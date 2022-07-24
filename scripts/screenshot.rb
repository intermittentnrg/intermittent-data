#!/usr/bin/env ruby
require 'bundler/setup'
require "selenium-webdriver"

#client = Selenium::WebDriver::Remote::Http::Default.new
#client.read_timeout = 180 # seconds
#driver = Selenium::WebDriver.for :remote, url: 'http://localhost:4444', desired_capabilities: :chrome, http_client: client

driver = Selenium::WebDriver.for :remote, url: "http://localhost:4444/wd/hub", capabilities: :firefox
driver.manage.window.resize_to(3840, 2160) # <- resizes the window

driver.navigate.to "https://intermittent.energy/d/3sj6qwA7z/load-solar-wind-nuclear?orgId=1&from=now-1y&to=now&kiosk=tv"

width  = driver.execute_script("return Math.max(document.body.scrollWidth,document.body.offsetWidth,document.documentElement.clientWidth,document.documentElement.scrollWidth,document.documentElement.offsetWidth);")
height = driver.execute_script("return Math.max(document.body.scrollHeight,document.body.offsetHeight,document.documentElement.clientHeight,document.documentElement.scrollHeight,document.documentElement.offsetHeight);")

driver.manage.window.resize_to(width, height) # <- resizes the window
picture = driver.screenshot_as(:png)

File.open('picture2.png', 'w+') do |fh|
  fh.write picture
end

driver.quit
