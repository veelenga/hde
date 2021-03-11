require "./spec_helper"
require "../src/html_date"

def it_extracts_file(date : String, file)
  html = File.read(file)
  it_extracts(date, html)
end

def it_extracts(date : String, html : String)
  it { HtmlDate.new.extract_from_html(html).should eq(date) }
end

def it_doesnt_extract(html : String)
  it { HtmlDate.new.extract_from_html(html).should be_nil }
end

describe HtmlDate do
  describe "#extract_from_html" do
    describe "meta nodes" do
      it_extracts_file "Jun 10, 2019", "spec/assets/analyticsvidhya.com.html"
      it_extracts_file "Mar 12, 2020", "spec/assets/edition.cnn.com.html"

      it_extracts "Sep 1, 2017", %q(<html><head><meta property="dc:created" content="2017-09-01"/></head><body></body></html>)
      it_extracts "Sep 1, 2017", %q(<html><head><meta property="og:published_time" content="2017-09-01"/></head><body></body></html>)
      it_extracts "Sep 1, 2017", %q(<html><head><meta http-equiv="date" content="2017-09-01"/></head><body></body></html>)
      it_extracts "Sep 1, 2017", %q(<html><head><meta name="last-modified" content="2017-09-01"/></head><body></body></html>)
      it_extracts "Sep 1, 2017", %q(<html><head><meta property="OG:Updated_Time" content="2017-09-01"/></head><body></body></html>)
      it_extracts "Sep 1, 2017", %q(<html><head><Meta Property="og:updated_time" content="2017-09-01"/></head><body></body></html>)
      it_extracts "Sep 1, 2017", %q(<html><head><meta name="created" content="2017-09-01"/></head><body></body></html>)

      # invalid date
      it_doesnt_extract %q(<html><head><meta name="created" content="1930-09-01"/></head><body></body></html>)
      it_doesnt_extract %q(<html><head><meta name="created" content="9999-09-01"/></head><body></body></html>)
    end

    describe "ldjson" do
      it_extracts_file "Dec 7, 2020", "spec/assets/gardeningknowhow.com.html"
    end

    describe "abbr nodes" do
      it_extracts "Nov 12, 2016", %q(<html><body><abbr class="published">am 12.11.16</abbr></body></html>)
      it_extracts "Nov 12, 2016", %q(<html><body><abbr class="published" title="2016-11-12">XYZ</abbr></body></html>)
      it_extracts "Nov 8, 2020", %q(<html><body><abbr class="date-published">8.11.2016</abbr></body></html>)
      it_extracts "Jul 28, 2015", %q(<html><body><abbr data-utime="1438091078" class="something">A date</abbr></body></html>)

      # invalid date-utime
      it_doesnt_extract %q(<html><body><abbr data-utime="143809-1078" class="something">A date</abbr></body></html>)
    end

    describe "time nodes" do
      it_extracts "Jan 4, 2018", %q(<html><body><time>2018-01-04</time></body></html>)

      # https://www.w3schools.com/TAgs/att_time_datetime_pubdate.asp
      it_extracts "Sep 28, 2011", %q(<html><body><time datetime="2011-09-28" pubdate="pubdate"></time></body></html>)
      it_extracts "Sep 28, 2011", %q(<html><body><time datetime="2011-09-28" class="entry-date"></time></body></html>)

      it_doesnt_extract %q(<html><body><time datetime="2011-09-28" class="test"></time></body></html>)
      it_doesnt_extract %q(<html><body><time datetime="2011-09-28"></time></body></html>)
    end

    describe "timestamp search" do
      it_extracts_file "Feb 2, 2020", "spec/assets/github.com.html"
    end

    describe "copyright" do
      # https://www.metatags.org/all-meta-tags-overview/meta-name-copyright/
      it_extracts "Jan 1, 2017", %q(<html><head><meta itemprop="copyrightyear" content="2017"/></head><body></body></html>)
      it_extracts "Jan 1, 2017", %q(<html><body>&copy; 2017</body></html>)
      it_extracts "Jan 1, 2017", %q(<html><body>© 2017</body></html>)
    end

    it_doesnt_extract %q(<html><head><meta/></head><body></body></html>)
    it_doesnt_extract %q(<html><body><time datetime="08:00"></body></html>)
    it_doesnt_extract %q(<html><body><p>It could not be 03/03/2077 or 03/03/1988.</p></body></html>)
  end
end
