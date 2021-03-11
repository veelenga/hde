require "sanitize"

class Sanitize::Blacklist < Sanitize::Policy
  def initialize(@rejectable_tags : Array(String))
  end

  def transform_text(text : String) : String?
    text
  end

  def transform_tag(name : String, attributes : Hash(String, String)) : String | CONTINUE | STOP
    return Sanitize::Policy::STOP if @rejectable_tags.includes?(name)

    transform_attributes(name, attributes)
  end

  def transform_attributes(name : String, attributes : Hash(String, String)) : String | CONTINUE | STOP
    name
  end
end
