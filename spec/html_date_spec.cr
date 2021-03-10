require "./spec_helper"
require "../src/html_date"

describe HtmlDate do
  describe ".extract_from_html" do
    it "extracts date from meta in header" do
      html = File.read("spec/assets/analyticsvidhya.com.html")
      date = HtmlDate.extract_from_html(html)
      date.should eq("Jun 10, 2019")
    end

    it "extracts date from meta in body" do
      html = File.read("spec/assets/edition.cnn.com.html")
      date = HtmlDate.extract_from_html(html)
      date.should eq("Mar 12, 2020")
    end

    it "extracts date from ldjson" do
      html = File.read("spec/assets/gardeningknowhow.com.html")
      date = HtmlDate.extract_from_html(html)
      date.should eq("Dec 7, 2020")
    end
  end
end
