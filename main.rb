require 'fileutils'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'pry'

# MIT License

# Copyright (c) 2019 iqbal rifai

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


class NhentaiDownloader

  def initialize(kode_nuklir)
    @kode_nuklir = kode_nuklir
    parse_halaman = Nokogiri::HTML.parse(open("https://id.nhent.ai/g/#{@kode_nuklir}/"))
    fungsi_meta = parse_halaman.xpath("//meta").collect { |meta|
      ar = meta.attributes.values.collect(&:value)
      {ar[0] => ar[1]}
    }.compact.reduce({}, :merge)
    @id_galeri = fungsi_meta["image"][/\d+/]
    @judul = fungsi_meta["name"]
    @banyak_halaman = parse_halaman.at_css("div#info").children[7].children.text.split.first.to_i
    @tagar = {}
    links = parse_halaman.css("section#tags")[0].xpath(".//span/a").collect { |a| a.attributes["href"].value }
    links.each do |link|
      parts = link[1..-2].split '/'
      @tagar[parts[0]] = @tagar[parts[0]] || []
      @tagar[parts[0]] << parts[1]
    end
  end

  def rip
    Dir.mkdir @judul unless Dir.exist? @judul
    open("./#{@judul}/metadata.json", 'w') do |file|
      file.write(JSON.pretty_generate(metadata))
    end
    existing = Dir.glob("./#{@judul}/*.{jpg,png}").map { |path| path[/\d+/].to_i }
    for page in 1..@banyak_halaman
      if existing.include? page
        puts "Skipping #{page}:'#{@judul}'"
      else
        rip_image page
      end
    end
  end

  def metadata
    metadata = {}
    metadata[:id] = @kode_nuklir
    metadata[:title] = @judul
    metadata[:gallery_id] = @id_galeri
    metadata[:num_pages] = @banyak_halaman
    metadata.merge! @tagar
    metadata
  end

  private

  def rip_image(i)
    begin
      image = open("https://i.bakaa.me/galleries/#{@id_galleri}/#{i}.png").read
      ext = 'png'
    rescue OpenURI::HTTPError
      image = open("https://i.bakaa.me/galleries/#{@id_galleri}/#{i}.jpg").read
      ext = 'jpg'
    end
    title = "./#{@judul}/#{i}.#{ext}"
    open(title, 'wb') do |file|
      file << image
    end
    puts "Didownload: #{i}:'#{@judul}'"
  end
end
