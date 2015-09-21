#!/usr/bin/env ruby

require 'erb'
require 'uri'
#require 'redcarpet'
require 'metadown'
require 'html_truncator'
require 'date'

class Entry
  attr_accessor :timestamp, :title, :content, :truncated_content,
    :uri, :datetime

  def initialize(timestamp, title, content)
    @timestamp = timestamp
    @title = URI.decode(title)
    @content = content
    @truncated_content = content
    @datetime = DateTime.strptime(timestamp, '%s').strftime('%B %m, %Y')
    @uri = uri
  end

  def render
    data = Metadown.render(@content)
    @content = data.output
    @title = data.metadata["title"] if data.metadata["title"]
    @truncated_content = HTML_Truncator.truncate(@content, 55, :ellipsis => "… <a href=\"#{@uri}\">read more</a>")
    self
  end

  def uri
    @uri ||= "/entry/#{URI.encode(@timestamp)}-#{URI.encode(@title)}.html"
  end

  def to_h
    { timestamp: @timestamp, title: @title, content: @content, truncated_content: @truncated_content, datetime: @datetime }
  end
end

class Changelog
  attr_accessor :entries

  def initialize(entries)
    @entries = entries
  end

  def get_binding
    binding()
  end
end

def load_entries(dir)
  entries = []

  Dir.foreach(dir) do |entry_file|
    next unless File.file? "#{dir}/#{entry_file}"
    next unless entry_file =~ /^([-]?\d+)-(.+)\.md$/
    entry = Entry.new($1, $2, File.read("#{dir}/#{entry_file}"))
    entries << entry.render.to_h
  end

  entries
end

dir = "entries"
changelog = Changelog.new(load_entries(dir))
renderer = ERB.new(File.read('tmpl/layout.erb'))
puts renderer.result(changelog.get_binding)
