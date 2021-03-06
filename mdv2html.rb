#!/usr/bin/env ruby
# vim: foldmethod=marker
require 'date'
require 'rubygems'
require 'kramdown'

class Kramdown::Parser::MarkdownVimhacks < Kramdown::Parser::Kramdown
  def initialize(source, options)
    super
    @span_parsers.delete(:smart_quotes)
  end
end

def mdv2html(text)
  text = text.lines.to_a[1..-1].join # Just ignore the first line
  body = Kramdown::Document.new(text, :auto_ids => false, :input => 'MarkdownVimhacks').to_html
  body.gsub!(%r!<img (.*?) />fit!, '<img \1 style="width: 100%;" />')
  body.gsub!(%r!<code>\|(.*?)\|</code>!, '<kbd>\1</kbd>')

  body = body.split(/\n/).map {|line|
    if (/<code>/ =~ line) .. (/<\/code>/ =~ line)
      line
    else
      line.gsub(%r!'[a-z]+?'!, '<code class="option">\0</code>')
    end
  }.join "\n"

  body.gsub!(%r!^<p>Author: (.*?)</p>$!, '<address class="hack-author">\1</address>') # FIXME: It should apply ONLY for the last line
  body
end

def html2mdv(html)
  html = html.gsub(%r!<address class="hack-author">(.*)</address>!, '<p>Author: \1</p>')
  html = html.gsub(%r!<code class="option">(.*?)</code>!, %q!\1!)
  html = html.gsub(%r!<kbd>(.*?)</kbd>!, '<code>|\1|</code>')
  html = html.gsub(%r!<img (.*) style="width: 100%;" />!, '<img \1 />fit')
  IO.popen('html2markdown', 'r+') {|io|
    io.puts html
    io.close_write
    io.read
  }
end

def headerline2hash(line)
  m = line.match(/^# Hack #(\d+): (.*?) \| (.*?) (.*?)$/)
  {
    :hacknum => m[1].to_i,
    :title => m[2],
    :level => m[3],
    :date => Date.parse(m[4])
  }
end

case $0
when __FILE__
  puts mdv2html(ARGF.read)
when /spec$/
  fixture =
    <<-EOF.gsub(/^\s+\|/, '').chomp # {{{
    |# Hack #22: Ultra Super Great Vim Plugin | lv2 2009-06-06
    |
    |## PROBLEM
    |blah blah blah
    |
    |## SOLUTION
    |use [blogger.vim](http://www.vim.org/scripts/script.php?script_id=2638)
    |with
    |
    |the key mapping `|j|`.
    |
    |## DISCUSSION
    |blah blah blah
    |
    |    nnoremap j :<C-u>1000sl<Cr>
    |    nnoremap k :<C-u>1000sl<Cr>
    |    call echo('hi')
    |
    |blah blah blah. hara y y hara y?
    |
    |A nice option 'number' is great.
    |
    |This is not an option: ''.
    |
    |![A](http://aaa.jpg)fit
    |
    |![A](http://aaa.jpg)
    |
    |Author: ujihisa
    EOF
    # }}}

  html =
      <<-EOF.gsub(/^\s+\|/, '').chomp # {{{
      |<h2>PROBLEM</h2>
      |
      |<p>blah blah blah</p>
      |
      |<h2>SOLUTION</h2>
      |
      |<p>use <a href="http://www.vim.org/scripts/script.php?script_id=2638">blogger.vim</a>
      |with</p>
      |
      |<p>the key mapping <kbd>j</kbd>.</p>
      |
      |<h2>DISCUSSION</h2>
      |
      |<p>blah blah blah</p>
      |
      |<pre><code>nnoremap j :&lt;C-u&gt;1000sl&lt;Cr&gt;
      |nnoremap k :&lt;C-u&gt;1000sl&lt;Cr&gt;
      |call echo('hi')
      |</code></pre>
      |
      |<p>blah blah blah. hara y y hara y?</p>
      |
      |<p>A nice option <code class="option">'number'</code> is great.</p>
      |
      |<p>This is not an option: ''.</p>
      |
      |<p><img src="http://aaa.jpg" alt="A" style="width: 100%;" /></p>
      |
      |<p><img src="http://aaa.jpg" alt="A" /></p>
      |
      |<address class="hack-author">ujihisa</address>
      EOF
      # }}}

  describe 'mdv2html' do
    it 'encodes mdv text to html text' do
      mdv2html(fixture).should be_instance_of(String)
      mdv2html(fixture).should == html
    end
  end

  describe 'html2mdv' do
    it 'decodes html text to mdv text' do
      # FIXME: Add headline
      mdv =
        <<-EOF.gsub(/^\s+\|/, '').chomp # {{{
        |## PROBLEM
        |
        |blah blah blah
        |
        |## SOLUTION
        |
        |use
        |[blogger.vim](http://www.vim.org/scripts/script.php?script_id=2638)
        |with
        |
        |the key mapping `|j|`.
        |
        |## DISCUSSION
        |
        |blah blah blah
        |
        |    nnoremap j :<C-u>1000sl<Cr>
        |    nnoremap k :<C-u>1000sl<Cr>
        |    call echo('hi')
        |
        |blah blah blah. hara y y hara y?
        |
        |A nice option 'number' is great.
        |
        |This is not an option: ''.
        |
        |![A](http://aaa.jpg)fit
        |
        |![A](http://aaa.jpg)
        |
        |Author: ujihisa
        |
        |
        |
        |
        EOF
        # }}}

      html2mdv(html).should be_instance_of(String)
      html2mdv(html).should == mdv
    end
  end


  describe 'headerline2hash' do
    it 'gets hash from a line of header' do
      hash = {
        :date => Date.parse('2009-06-06'),
        :level => "lv2",
        :hacknum => 22,
        :title => "Ultra Super Great Vim Plugin"
      }
      headerline2hash(fixture.lines.to_a.first).should == hash
    end
  end
end
