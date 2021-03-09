require "./spec_helper"
require "../src/html_date"

describe HtmlDate do
  describe ".extract_from_html" do
    it "extracts date from html" do
      html = File.read("spec/assets/analyticsvidhya.com.html")
      date = HtmlDate.extract_from_html(html)
      date.should eq("Jun 10, 2019")
    end
  end
end
