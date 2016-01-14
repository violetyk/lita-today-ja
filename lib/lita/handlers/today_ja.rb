require 'open-uri'
require 'active_support'
require 'active_support/core_ext'
require 'nokogiri'
require 'html2markdown'

module Lita
  module Handlers
    class TodayJa < Handler

      route(/^(.+)$/, command: true) do |response|
        response.matches.flatten.first.gsub(/　/, ' ').split.each do |v|
          date = parse_date(v.try(:strip))
          unless date.nil?
            response.reply(<<-STR)
#{date.strftime('%Y年%-m月%-d日')}（#{wday(date)}）
```
（´-`）.｡oO（Wikipediaから読んできました）

#{wikipedia(date)}
```
```
（´-`）.｡oO（HINETから読んできました）

#{hinet(date)}
```
            STR
          end
        end
      end

      def hinet(date)
        params = {
          conf: 'today.pro',
          d: date.strftime('%b %-d,%Y'),
        }
        charset = nil
        response = open('http://today.hakodate.or.jp/apps/Today/Content?' << params.to_query) do |f|
          charset = f.charset
          f.read
        end
        xml = Nokogiri::HTML.parse(response, nil, charset)
        xml.search('br').each { |br| br.replace("\n") }
        xml.xpath('//html/body/ul').inner_text
      end

      def wikipedia(date)
        params = { titles: date.strftime('%-m月%-d日') }
        content = call_wikipedia_api(params)
        rvsection = content.search('span.toctext').each_with_index do |node, i|
          break i + 1 if node.inner_text == '記念日・年中行事'
        end
        return nil unless rvsection.is_a?(Integer) && rvsection > 0 # not found

        doc = call_wikipedia_api(params.merge({ rvsection: rvsection }))
        Nokogiri::HTML(doc.to_html).text
          .gsub(/\[編集\]/, '')
          .gsub(/^\n$^\n$/, "\n")
      end

      def call_wikipedia_api(params = {})
        params.merge!({
          format: 'xml',
          action: 'query',
          prop: 'revisions',
          rvprop: 'content',
          rvparse: nil,
        })
        charset = nil
        response = open('https://ja.wikipedia.org/w/api.php?' << params.to_query) do |f|
          charset = f.charset
          f.read
        end

        xml = Nokogiri::HTML.parse(response, nil, charset)
        content = Nokogiri::HTML.parse(CGI.unescapeHTML(xml.xpath('//api/query/pages/page/revisions/rev').to_html), nil, charset)
        content = yield content if block_given?
        content
      end

      def parse_date(str)
        date = nil
        begin
          date = DateTime.parse(str)
        rescue ArgumentError
          [
            '%Y年%m月%d日',
            '%m月%d日',
          ].each do |format|
            begin
              break date =  DateTime.strptime(str, format)
            rescue ArgumentError
              date = case str
              when three_days_before_yesterday?; Date.today - 4
              when two_days_before_yesterday?; Date.today - 3
              when day_before_yesterday?; Date.today - 2
              when yesterday?; Date.today - 1
              when today?; Date.today
              when tomorrow?; Date.today + 1
              when day_after_tomorrow?; Date.today + 2
              when two_days_after_tomorrow?; Date.today + 3
              when three_days_after_tomorrow?; Date.today + 4
              else
                match = str.tr('０-９', '0-9').match(/^(\d+)日([前後])/)
                unless match.nil?
                  if m[2] == '前'
                    Date.today + m[1]
                  else
                    Date.today - m[1]
                  end
                end
              end
            end
          end
        end
        date
      end


      def three_days_before_yesterday?
        ->v{ [ '四日前', 'よっかまえ', ].include? v }
      end

      def two_days_before_yesterday?
        ->v{ [
          '一昨昨日', '一昨々日', 'いっさくさくじつ', 'さきおととい',
          '三日前', 'みっかまえ',
          '前々々日', 'ぜんぜんぜんじつ',
        ].include? v }
      end

      def day_before_yesterday?
        ->v{ [
          '一昨日', 'いっさくじつ', 'おととい',
          '二日前', 'ふつかまえ',
          '前の前の日', 'まえのまえのひ',
          '前々日', 'ぜんぜんじつ',
        ].include? v }
      end

      def yesterday?
        ->v{ [
          '昨日', 'さくじつ', 'きのう',
          '前日', 'ぜんじつ',
        ].include? v }
      end

      def today?
        ->v{ [
          '本日', 'ほんじつ',
          '今日', 'きょう',
          '当日', 'とうじつ',
        ].include? v }
      end

      def tomorrow?
        ->v{ [
          '明日', 'あした', 'みょうにち', 'あす',
          '一日後', 'いちにちご',
          '翌日', 'よくじつ',
          '次の日', 'つぎのひ',
        ].include? v }
      end

      def day_after_tomorrow?
        ->v{ [
          '明後日', 'みょうごにち', 'あさって',
          '二日後', 'ふつかご',
          '次の次の日', 'つぎのつぎのひ',
          '翌々日', 'よくよくじつ',
        ].include? v }
      end

      def two_days_after_tomorrow?
        ->v{ [
          '明明後日', '明々後日', 'みょうみょうごにち', 'しあさって',
          '三日後', 'みっかご',
          '翌々々日', 'よくよくよくじつ',
        ].include? v }
      end

      def three_days_after_tomorrow?
        ->v{ [
          '弥の明後日', 'やのあさって',
          '四日後', 'よっかご',
        ].include? v }
      end

      def wday(date)
        wdays = %w(日 月 火 水 木 金 土)
        wdays[date.wday]
      end

      Lita.register_handler(self)
    end
  end
end
