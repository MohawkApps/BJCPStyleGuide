class MainScreen < ProMotion::SectionedTableScreen
  title "2008 BJCP Styles"
  searchable :placeholder => "Search Styles"

  def will_appear
    @view_set_up ||= begin
      set_attributes self.view, { backgroundColor: UIColor.whiteColor }

      unless Device.ipad?
        set_nav_bar_right_button UIImage.imageNamed("info.png"), action: :open_about_screen
      end

      backBarButtonItem = UIBarButtonItem.alloc.initWithTitle("Back", style:UIBarButtonItemStyleBordered, target:nil, action:nil)
      self.navigationItem.backBarButtonItem = backBarButtonItem

      @reload_observer = App.notification_center.observe "ReloadNotification" do |notification|
        @table_setup = nil
        update_table_data
      end

      # Check to see if we should go directly into a style when the app is already loaded.
      @style_observer ||= App.notification_center.observe "GoDirectlyToStyle" do |notification|
        App.delegate.jump_to_style = notification.object[:object]
      end

      read_data
    end
  end

  def auto_open_style(style)
    cat = style[0..-2].to_i
    subcat = style[-1]

    # Find it in the array
    requested_style = @styles[cat - 1][:substyles][subcat.as_integer - 1]
    App.delegate.jump_to_style = nil

    if requested_style.nil?
      App.alert "Invalid style requested: \"#{style}\"."
    else
      # TODO: Pop back to the root view controller
      # pop_to_root animated: false
      open_style style: requested_style

      # TODO:
      # Scroll down to the correct section on the ipad
    end
  end

  def on_appear
    toolbar_animated = Device.ipad? ? false : true
    self.navigationController.setToolbarHidden(true, animated:toolbar_animated)

    # Check to see if we should go directly into a style when the app is not in memory.
    auto_open_style App.delegate.jump_to_style unless App.delegate.jump_to_style.nil?

    # Re-call on_appear when the application resumes from the background state since it's not called automatically.
    @on_appear_observer ||= App.notification_center.observe UIApplicationDidBecomeActiveNotification do |notification|
      on_appear
    end

  end

  def table_data
    return [] if @styles.nil?
    @table_setup ||= begin
      s = []
      s << judging_section unless judging_section.nil?
      s << {
        title: "Introductions",
        cells: [
          intro_cell("Beer Introduction"),
          intro_cell("Mead Introduction"),
          intro_cell("Cider Introduction")
        ]
      }

      @styles.each do |section|
        s << {
          title: "#{section[:id]}: #{section[:name]}",
          cells: build_subcategories(section)
        }
      end
      s
    end
  end

  def intro_cell(name)
    {
      title: name,
      searchable: false,
      cell_identifier: "IntroductionCell",
      action: :open_intro_screen,
      arguments: {:file => "#{name}.html", :title => name}
    }
  end

  def judging_section
    if BeerJudge.is_installed?
      # Show the judging Tools
      return {
        title: "Judging Tools",
        cells: judging_cells
      }
    else
      # Should we show the section at all?
      if shows_beer_judging_section?
        # Show the intro screen
        return {
          title: "Judging Tools",
          cells: [{
            title: "Check Out the App!",
            searchable: false,
            cell_identifier: "JudgingCell",
            action: :open_judging_info_screen,
            image: {
              image:"judge.png",
              radius: 8
            }
          }]
        }
      end
    end
    nil
  end

  def shows_beer_judging_section?
    return true if BeerJudge.is_installed?
    App::Persistence['hide_judging_tools'].nil? ||  App::Persistence['hide_judging_tools'] == false
  end

  def judging_cells
    c = []
    %w(Flavor\ Wheel SRM\ Spectrum SRM\ Analyzer).each do |tool|
      downcased_tool = tool.downcase.tr(" ", "_")
      c << {
        title: tool,
        searchable: false,
        cell_identifier: "JudgingCell",
        action: :open_judging_tool,
        arguments: {url: downcased_tool},
        image: "judge_#{downcased_tool}.png"
      }
    end
    c
  end

  def build_subcategories(section)
    c = []
    section[:substyles].each do |subcat|
      c << {
        title: subcat.title,
        search_text: subcat.search_text,
        cell_identifier: "SubcategoryCell",
        action: :open_style,
        arguments: {:style => subcat}
      }
    end
    c
  end

  def table_data_index
    return if table_data.count < 1
    # Get the style number of the section
    drop = shows_beer_judging_section? ? 2 : 2
    droped_intro = shows_beer_judging_section? ? ["{search}", "J", "?"] : ["{search}", "?"]

    droped_intro + table_data.drop( drop ).collect do |section|
      section[:title].split(" ").first[0..-2]
    end
  end

  def open_style(args={})
    if Device.ipad?
      open DetailScreen.new(args), nav_bar:true, in_detail: true
    else
      open DetailScreen.new(args)
    end
  end

  def open_about_screen(args={})
    open_modal AboutScreen.new(external_links: true),
      nav_bar: true,
      presentation_style: UIModalPresentationFormSheet
  end

  def open_intro_screen(args={})
    if Device.ipad?
      open IntroScreen.new(args), nav_bar:true, in_detail: true
    else
      open IntroScreen.new(args)
    end
  end

  def open_judging_info_screen
    open_modal JudgingInfoScreen.new, nav_bar: true, presentation_style: UIModalPresentationFormSheet
  end

  def open_judging_tool(args={})
    BeerJudge.open(args[:url])
  end

  private
  def read_data
    @done_read_data ||= begin

      @styles = []
      db = SQLite3::Database.new(File.join(App.resources_path, "styles.sqlite"))
      db.execute("SELECT * FROM category ORDER BY id") do |row|
        substyles = []
        db.execute("SELECT * FROM subcategory WHERE category = #{row[:id]} ORDER BY id") do |row2|
          substyles << Style.new(row2)
        end
        row[:substyles] = substyles
        @styles << row
      end

      @table_setup = nil
      update_table_data
    end
  end

end
