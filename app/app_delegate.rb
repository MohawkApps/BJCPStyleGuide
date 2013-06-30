class AppDelegate < ProMotion::Delegate

  attr_accessor :jump_to_style

  def on_load(app, options)

    if defined? TestFlight
      TestFlight.setDeviceIdentifier UIDevice.currentDevice.uniqueIdentifier
      TestFlight.takeOff "e9a2e874-1b13-426c-ad0f-6958e7b2889c"
    end

    # 3rd Party integrations
    unless Device.simulator?
      app_id = NSBundle.mainBundle.objectForInfoDictionaryKey('APP_STORE_ID')

      # Flurry
      NSSetUncaughtExceptionHandler("uncaughtExceptionHandler")
      Flurry.startSession("YSNRBSKM9B3ZZXPG7CG7")

      # Appirater
      Appirater.setAppId app_id
      Appirater.setDaysUntilPrompt 5
      Appirater.setUsesUntilPrompt 10
      Appirater.setTimeBeforeReminding 5
      Appirater.appLaunched true

      # Harpy
      Harpy.sharedInstance.setAppID app_id
      Harpy.sharedInstance.checkVersion
    end

    # Set initial font size (%)
    if App::Persistence['font_size'].nil?
      App::Persistence['font_size'] = 100
    end

    # Check to see if the user is calling a style from an external URL when the application isn't in memory yet
    if defined?(options[UIApplicationLaunchOptionsURLKey])
      suffix = options[UIApplicationLaunchOptionsURLKey].absoluteString.split("//").last
      open_style_when_launched suffix
    end

    main_screen = MainScreen.new(nav_bar: true)

    if Device.ipad?
      open_split_screen main_screen, DetailScreen.new(nav_bar: true), title: "Split Screen Title"
    else
      open main_screen
    end
  end

  #Flurry exception handler
  def uncaughtExceptionHandler(exception)
    Flurry.logError("Uncaught", message:"Crash!", exception:exception)
  end

  def applicationWillEnterForeground(application)
    Appirater.appEnteredForeground true unless Device.simulator?
  end

  def application(application, openURL:url, sourceApplication:sourceApplication, annotation:annotation)
    suffix = url.absoluteString.split("//").last

    if suffix == "reset_tools"
      App::Persistence['hide_judging_tools'] = nil
      App.notification_center.post "ReloadNotification"
    else
      open_style_when_launched suffix
    end

    true
  end

  def open_style_when_launched(style)
      self.jump_to_style = style
      App.notification_center.post("GoDirectlyToStyle", object:style)
  end

end
