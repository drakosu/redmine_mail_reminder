class MailReminderMailer < ActionMailer::Base
  helper :application
  helper :issues
  helper :mail_reminders
  include Redmine::I18n

  # Constants
  AUTHOR_ONLY ||= 'author only'
  ASSIGNEE_ONLY ||= 'assignee only'

  def self.default_url_options
    h = Setting.host_name
    h = h.to_s.gsub(%r{\/.*$}, '') unless Redmine::Utils.relative_url_root.blank?
    { :host => h, :protocol => Setting.protocol }
  end

  # Fixed: reminder mails are not sent when delivery_method is :async_smtp (#5058).
  def self.with_synched_deliveries(&block)
    saved_method = ActionMailer::Base.delivery_method
    if m = saved_method.to_s.match(%r{^async_(.+)$})
      synched_method = m[1]
      ActionMailer::Base.delivery_method = synched_method.to_sym
      ActionMailer::Base.send "#{synched_method}_settings=", ActionMailer::Base.send("async_#{synched_method}_settings")
    end
    yield
  ensure
    ActionMailer::Base.delivery_method = saved_method
  end

  def issues_reminder(user, queries_data)
    User.current = user
    @queries_data = []
    queries_data.each do |project, query, additional_filtering|
      query.project = project
      options = {:include => [:assigned_to, :tracker, :priority, :category, :fixed_version]}
      case additional_filtering
      when AUTHOR_ONLY
        options[:conditions] = {:author_id => user.id}
      when ASSIGNEE_ONLY
        options[:conditions] = {:assigned_to_id => user.id}
      end
      issues = query.issues(options)
      @queries_data << [project, query, issues] if issues.any?
    end

    # Not Sending email if there are no issues
    original_delivery_method = ActionMailer::Base.delivery_method
    if @queries_data.empty?
      ActionMailer::Base.delivery_method = :test
    else
      BoardsWatchers.logger.info(user.mail)
    end

    headers['X-Mailer'] = 'Redmine'
    headers['X-Redmine-Host'] = Setting.host_name
    headers['X-Redmine-Site'] = Setting.app_title
    headers['X-Auto-Response-Suppress'] = 'OOF'
    headers['Auto-Submitted'] = 'auto-generated'
    headers['From'] = Setting.mail_from
    headers['List-Id'] = "<#{Setting.mail_from.to_s.gsub('@', '.')}>"

    set_language_if_valid user.language
    mail :to => user.mail,
      :from => Setting.mail_from,
      :subject => Setting.plugin_redmine_mail_reminder['issue_reminder_mail_subject'] || "Issue Reminder"
    ActionMailer::Base.delivery_method = original_delivery_method
  end
end
