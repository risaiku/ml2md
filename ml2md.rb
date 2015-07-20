#!/usr/local/bin/ruby
# coding: utf-8

#
# ml2md.rb
# v0.1
#
# Copyright (c) 2015 risaiku
# This software is released under the MIT License.
#
# http://risaiku.net
# https://github.com/risaiku/ml2md
#

require 'date'
require 'fileutils'
require 'mail'
require 'set'
require 'yaml'

yml = YAML.load_file(File.dirname(__FILE__) + '/ml2md.yml')

ROOT_DIR = 'attachment'
NAV_FILE = 'navigation.md'
OK_ADDRS = yml['ok_addrs']
OUT_PATH = yml['out_path']

def get_last_line(file_path)
    last_line = ''
    open(file_path) do |file|
        lines = file.read
        lines.each_line do |line|
            last_line = line
        end
    end
    return last_line
end

def get_body(m)
    if m.multipart? then
        if m.text_part then
            return m.text_part.decoded
        elsif m.html_part then
            return m.html_part.decoded
        end
    else
        return m.body.decoded.encode('UTF-8', m.charset)
    end

    return nil
end

mail = Mail.new(STDIN.read)

addr = mail.from.first

unless OK_ADDRS.include?(addr) then
    exit(0)
end

subject     = mail.subject ? mail.subject.encode('UTF-8') : ''
body        = get_body(mail)
attachments = mail.attachments

last_line = get_last_line(OUT_PATH + NAV_FILE)

TIME    = Time.now
TIME_Y  = TIME.strftime('%Y')
TIME_M  = TIME.strftime('%m')
TIME_D  = TIME.strftime('%d')
TIME_YM = TIME_Y + TIME_M
YMDHMS  = TIME.strftime('%Y-%m-%d %H:%M:%S')
PREFIX  = TIME.strftime('%Y%m%d%H%M%S')
create  = false

if last_line.include?(TIME_Y) then

    if last_line.include?(TIME_YM) then

    else

        # 年月のリンク出力
        File.open(OUT_PATH + NAV_FILE, 'a') do |file|
            file.write "\n  * [#{TIME_M}](#{TIME_YM}.md)"
            create = true
        end

    end

else

    # 新しい年だから、年の見出しと年月のリンク出力
    File.open(OUT_PATH + NAV_FILE, 'a') do |file|
        file.write "\n\n[#{TIME_Y}]()"
        file.write "\n\n  * [#{TIME_M}](#{TIME_YM}.md)"
        create = true
    end

end

if create then
    File.open(OUT_PATH + TIME_YM + '.md', 'w') do |file|
        file.puts TIME_Y + '/' + TIME_M
        file.puts '========='
        file.puts ''
    end
end

File.open(OUT_PATH + TIME_YM + '.md', 'a') do |file|

    file.puts '- - - -'
    file.puts YMDHMS + ' ' + subject
    file.puts "-------------"
    file.puts ''
    file.puts 'from : ' + addr
    file.puts ''
    body.each_line {|line| file.puts "    " + line}
    file.puts ''

    idx = 0

    attachments && attachments.each do |attachment|

        dir_path  = ROOT_DIR + '/' + TIME_Y + '/' + TIME_M + '/' + TIME_D
        file_name = PREFIX + '_' + idx.to_s + '_' + attachment.filename
        file_path = dir_path + '/' + file_name

        unless FileTest.exist?(OUT_PATH + dir_path) then
            FileUtils.mkdir_p(OUT_PATH + dir_path)
            FileUtils.chmod_R(0777, OUT_PATH + ROOT_DIR)
        end

        File.open(OUT_PATH + file_path, "w+b") {|f| f.write attachment.body.decoded}
        File.chmod(0644, OUT_PATH + file_path)

        if (attachment.content_type.start_with?('image/'))
            file.puts "![](./#{file_path})"
        else
            file.puts "[#{attachment.filename}](./#{file_path})"
        end

        idx += 1

    end

    file.puts ''
end

File.chmod(0644, OUT_PATH + TIME_YM + '.md')

