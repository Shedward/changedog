class Changedog < Formula
  desc "Writes list of recent releases with jira tasks"
  url "git@gitlab.m2.ru:vtblife/mobile/common/changedog.git", :using => :git, :tag => "v1.1"
  version "1.1"

  uses_from_macos "swift" => :build

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

end