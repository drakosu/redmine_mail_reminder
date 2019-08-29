module MailRemindersHelper
  def queries_for_options(project_id, query_id = nil)
    # Project specific queries and global queries
    selectable_queries = IssueQuery.visible.order("#{Query.table_name}.name ASC").
      where(project_id.nil? ? ["project_id IS NULL"] : ["project_id IS NULL OR project_id = ?", project_id])
    s = []
    s << options_from_collection_for_select(selectable_queries, 'id', 'name', query_id)
    safe_join(s)
  end

  def reminders_intervals_for_options
    MailReminder.intervals.collect {|i| [l(i).capitalize, i.to_s]}
  end

  def content_for_column(column, issue)
    value = column.value(issue)

    case value.class.name
    when 'String'
      if column.name == :subject
        link_to issue.subject, issue_url(issue)
      else
        h(value)
      end
    when 'Time'
      format_time(value)
    when 'Date'
      format_date(value)
    when 'Fixnum', 'Float'
      if column.name == :done_ratio
        progress_bar(value, :width => '80px')
	  elsif column.name == :id
	    link_to h(value.to_s), issue_url(issue)
      else
        h(value.to_s)
      end
    when 'User'
      link_to "#{value.firstname} #{value.lastname}", user_url(value)
    when 'Project'
      link_to value.name, project_url(value)
    when 'Version'
      # Turn off link to version temporarly since
      # routes are not correct in the Redmine
      # version 1.2.1
      #link_to(h(value), version_url(value))
      h(value.name)
    when 'TrueClass'
      l(:general_text_Yes)
    when 'FalseClass'
      l(:general_text_No)
    when 'Issue'
      link_to value.subject, issue_url(value)
    else
      if column.name == :tags
        # Code from redmine_tags column_content_with_redmine_tags
        value.collect{ |t| render_tag_link(t) }.join(', ').html_safe
      else
        h(value)
      end
    end
  end

  # Code from redmine_tags tags_helper.rb
  def render_tag_link(tag, options = {})
    tag_bg_color = tag_color(tag)
    tag_fg_color = tag_fg_color(tag_bg_color)
    tag_style = "background-color: #{tag_bg_color}; color: #{tag_fg_color}"

    tag_name = tag.respond_to?(:name) ? tag.name : tag
    filters = [[:tags, '=', tag_name]]
    content = link_to_filter tag_name, filters, project_id: @project

    style =
        { class: 'tag-label-color',
          style: tag_style }

    content_tag 'span', content, style
  end

  def tag_color(tag)
    tag_name = tag.respond_to?(:name) ? tag.name : tag
    "##{ Digest::MD5.hexdigest(tag_name)[0..5] }"
  end

  def tag_fg_color(bg_color)
    # calculate contrast text color according to YIQ method
    # http://24ways.org/2010/calculating-color-contrast/
    r = bg_color[1..2].hex
    g = bg_color[3..4].hex
    b = bg_color[5..6].hex
    (r * 299 + g * 587 + b * 114) >= 128000 ? "black" : "white"
  end

  # Code from redmine_tags filters_helper.rb
  # returns link to the page with issues filtered by specified filters
  # === parameters
  # * <i>title</i> = link title text
  # * <i>filters</i> = filters to be applied (see <tt>link_to_filter_options</tt> for details)
  # * <i>options</i> = (optional) base options of the link
  # === example
  # link_to_filter 'foobar', [[ :tags, '~', 'foobar' ]]
  # link_to_filter 'foobar', [[ :tags, '~', 'foobar' ]], :project_id => project
  def link_to_filter(title, filters, options = {})
    options.merge! link_to_filter_options(filters)
    link_to title, options
  end

  # returns hash suitable for passing it to the <tt>to_link</tt>
  # === parameters
  # * <i>filters</i> = array of arrays. each child array is an array of strings:
  #                    name, operator and value
  # === example
  # link_to 'foobar', link_to_filter_options [[ :tags, '~', 'foobar' ]]
  #
  # filters = [[ :tags, '~', 'bazbaz' ], [:status_id, 'o']]
  # link_to 'bazbaz', link_to_filter_options filters
  def link_to_filter_options(filters)
    options = { controller: 'issues', action: 'index', set_filter: 1,
      fields: [], values: {}, operators: {}, f:[], v: {}, op: {} }

    filters.each do |f|
      name, operator, value = f

      options[:fields].push(name)
      options[:f].push(name)

      options[:operators][name] = operator
      options[:op][name]        = operator

      options[:values][name] = [value]
      options[:v][name]      = [value]
    end
    options
  end
end
