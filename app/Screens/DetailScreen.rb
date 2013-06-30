class DetailScreen < SizeableWebScreen
  attr_accessor :style, :cell

  def will_appear
    @view_loaded ||= begin

      if Device.ipad?
        set_nav_bar_right_button UIImage.imageNamed("info.png"), action: :open_about_screen
      end

      if defined? style.id
        self.setTitle the_title
        set_attributes view, {background_color:UIColor.whiteColor}
      else
        self.setTitle "Welcome"
        set_attributes view, {background_color:"#CCCC99".to_color}
      end
    end
  end

  def on_appear
    return unless defined? style.id
    super

    flurry_params = {style: the_title}
    Flurry.logEvent("ViewedStyle", withParameters:flurry_params) unless Device.simulator?
  end

  def the_title
    return "" unless defined? style.id
    "#{style.category}#{style.id.as_letter}: #{style.name}"
  end

  def load_finished
    super
    set_srm_range
  end

  def content
    return "DefaultScreen.html" if self.style.nil?

    <<-CONTENT

#{css}

<div class="srmrange">&nbsp;</div>
<h1>#{the_title}</h1>
<div class="srmrange">&nbsp;</div>

#{style.html(:aroma)}
#{style.html(:appearance)}
#{style.html(:flavor)}
#{style.html(:mouthfeel)}
#{style.html(:impression)}
#{style.html(:comments)}
#{style.html(:history)}
#{style.html(:ingredients)}
#{style.html(:specs)}
#{style.html(:examples)}

    CONTENT
  end

  def css
    "<style>" << File.read(File.join(App.resources_path, "style.css")) << "</style>"
  end

  def set_srm_range
    if style.nil? || style.srm_range.nil?
      gradient = "display:none;"
    else
      gradient = SRM.css_gradient(style.srm_range) unless style.nil?
    end
    evaluate "document.body.innerHTML += '<style>.srmrange{#{gradient}}</style>'"
  end

end
