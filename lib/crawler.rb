#!/usr/bin/env ruby
require File.expand_path('../../config/environment',  __FILE__)
require 'nokogiri'

class Crawler

  MAPPING = {
      'Oddiel' => 'section',
      'Obchodné meno' => 'businessName',
      'Sídlo' => 'address',
      'IČO' => 'ico',
      'Deň zápisu' => 'dateOfEntry',
      'Právna forma' => 'legalForm',
      'Predmet činnosti' => 'businessActivities',
      'Spoločníci' => 'companions',
      'Výška vkladu každého spoločníka' => 'eachMemberContribution',
      'Štatutárny orgán' => 'statutoryAuthority',
      'Konanie menom spoločnosti' => 'actingInCompanyName',
      'Základné imanie' => 'capital',
      'Ďalšie právne skutočnosti' => 'otherLegalFacts',
      'Spoločnosť zrušená od' => 'cancelledSince',
      'Právny dôvod zrušenia' => 'cancellationReason',
      'Deň výmazu' => 'dateOfDeletion',
      'Dôvod výmazu' => 'deletionReason',
      'Zlúčenie, splynutie, rozdelenie spoločnosti' => 'merge',
      'Právny nástupca' => 'legalSuccessor',
      'Likvidácia' => 'disposal',
      'Predaj' => 'sale',
      'Dozorná rada' => 'supervisorsBoard',
      'Spoločnosť zaniknutá zlúčením, splynutím alebo rozdelením' => 'merge2',
      'Akcie' => 'shares',
      'Vyhlásenie konkurzu' => 'bankruptcyDeclaration',
      'Správca konkurznej podstaty' => 'bankruptcyManager',
      'Ukončenie konkurzného konania' => 'bankruptcyTermination',
      'Zastupovanie' => 'representation',
      'Zakladateľ' => 'founder',
      'Kmeňové imanie' => 'shareCapital',
      'Odštepný závod' => 'branch',
      'Miesto podnikania' => 'placeOfBusiness',
      'Údaje o podnikateľovi'=> 'EntrepreneurDetails',
      'Bydlisko' => 'homeAddress',
      'Prokúra' => 'procuration',
      'Obchodné meno organizačnej zložky' => 'branchBusinessName',
      'Sídlo organizačnej zložky' => 'branchAddress',
      'Vedúci organizačnej zložky' => 'branchLeader',
      'Zahraničná osoba' => 'alien',
      'Konanie' => 'action',
      'Akcionár' => 'shareholder',
      'Kontrolná komisia' => 'auditComittee',
      'Zapisované základné imanie' => 'registeredCapital',
      'Základný členský vklad' => 'basicMemberContribution',
      'Povolenie reštrukturalizačného konania' => 'resctructuralizationAllowance',
      'Reštrukturalizačný správca' => 'restructuralizationChief',
      'Ukončenie reštrukturalizačného konania' => 'restructuralizationEnd',
      'Zriaďovateľ' => 'founder2'
  }

  def self.is_correct?()
    return @page.xpath("//*[contains(@class, 'wrn')]").size == 1
  end

  def self.process_string(str)
    if str
      str = str.to_s.strip.split.join(' ')
      str = str.gsub('"','')
    end

    return str || ''
  end

  def self.build_address(arr)
    if arr.size < 3
      return {
          :label => arr.map {|x| x.to_s.strip}.join(', '),
          :city => '',
          :zip => '',
          :country => 'Slovenská Republika'
      }
    end

    if arr.size == 3
      if arr[2].to_s.match(/\d\d\d.*/)
        return {
            :label => arr[0].to_s.strip.split.join(' '),
            :city => arr[1].to_s.strip.split.join(' '),
            :zip => arr[2].to_s.strip.split.join(' '),
            :country => 'Slovenská Republika'
        }
      else
        return {
            :label => arr[0..-2].map {|x| x.to_s.strip}.join(', '),
            :city => arr[-1].to_s.strip.split.join(' '),
            :zip => '',
            :country => 'Slovenská Republika'
        }
      end
    end

    if arr[-1].to_s.match(/\d\d\d.*/)
      return {
          :label => arr[0..-3].map {|x| x.to_s.strip}.join(', '),
          :city => arr[-2].to_s.strip.split.join(' '),
          :zip => arr[-1].to_s.strip.split.join(' '),
          :country => 'Slovenská Republika'
      }
    else
      return {
          :label => arr[0..-4].map {|x| x.to_s.strip}.join(', '),
          :city => arr[-3].to_s.strip.split.join(' '),
          :zip => arr[-2].to_s.strip.split.join(' '),
          :country => arr[-1].to_s.strip.split.join(' ')
      }
    end
  end

  def self.extract_basic_attribute(attr_name, span_order = 1)
    return process_string(@page.xpath("//table[not(ancestor::table)]/tr[td/span[@class='tl' and contains(text(), '#{attr_name}')]]/td[2]/table[1]/tr[1]/td[1]/span[#{span_order}]/text()"))
  end

  def self.extract_actualization_date
    return process_string(@page.xpath("//table[not(ancestor::table)]/tr[td[@class='tl' and contains(text(), 'Dátum aktualizácie údajov')]]/td[2]/text()")).gsub(/[^\w{\.}]/, '')
  end

  def self.extract_basic_list(identifier)
    business_activities = @page.xpath("//table[not(ancestor::table)]/tr[td/span[@class='tl' and contains(text(), '#{identifier}')]]/td[2]/table/tr[1]/td[1]/span/text()")
    return business_activities.map {|x| x.to_s.gsub(/[\r\n\t]/,'').strip.split.join(' ')}
  end

  def self.extract_companions
    companions = []
    @page.xpath("//table[not(ancestor::table)]/tr[td/span[@class='tl' and contains(text(), 'Spoločníci')]]/td[2]/table").each do |companion|
      title =  companion.xpath(".//a/preceding-sibling::span/text()")
      person = companion.xpath(".//a/span/text()")
      address = build_address(companion.xpath(".//a/following-sibling::span/text()"))

      companions << {
          :title => process_string(title),
          :person => {
              :firstName => process_string(person[0]),
              :lastName => process_string(person[1])
          },
          :address => address
      }
    end

    return companions
  end

  def self.extract_each_member_contribution
    contributions = []
    @page.xpath("//table[not(ancestor::table)]/tr[td/span[@class='tl' and contains(text(), 'Výška vkladu každého spoločníka')]]/td[2]/table").each do |companion|
      contributions << companion.xpath(".//tr[1]/td[1]/span/text()").map { |str| str.to_s.strip}.join(' ')
    end

    return contributions
  end

  def self.convert_number_to_float(number)
    return number == "" ? nil : number.gsub(/,/, '.').split.join('').to_f
  end

  def self.extract_basic_member_contribution
    return {
        size: convert_number_to_float(extract_basic_attribute('Základný členský vklad')),
        currency: extract_basic_attribute('Základný členský vklad', 2)
    }
  end

  def self.extract_capital
    return {
        size: extract_basic_attribute('Základné imanie') != "" ? convert_number_to_float(extract_basic_attribute('Základné imanie')) : convert_number_to_float(extract_basic_attribute('Zapisované základné imanie')),
        currency: extract_basic_attribute('Základné imanie', 2) != "" ? extract_basic_attribute('Základné imanie', 2) : extract_basic_attribute('Zapisované základné imanie', 2)
    }
  end

  def self.extract_statutory_authority
    members = []
    @page.xpath("//table[not(ancestor::table)]/tr[td/span[@class='tl' and contains(text(), 'Štatutárny orgán')]]/td[2]/table").each_with_index do |companion, index|
      if index > 0
        title =  companion.xpath(".//a/preceding-sibling::span/text()")
        person = companion.xpath(".//a/span/text()")
        position = ''
        since = ''
        other = companion.xpath(".//a/following-sibling::span/text()")

        if other[0].to_s.match(/.*-.*/)
          position = other[0].to_s.gsub('-','').strip.split.join(' ')
          other.shift
        end

        if other[-1].to_s.match(/.*Vznik funkcie.*/)
          since = other[-1].to_s.gsub('Vznik funkcie:','').strip.split.join(' ')
          other.pop
        end

        address = build_address(other)


        members << {
            :title => process_string(title),
            :position => position,
            :since => convert_to_date_format(since),
            :person => {
                :firstName => process_string(person[0]),
                :lastName => process_string(person[1])
            },
            :address => address
        }
      end
    end

    return {
        type: extract_basic_attribute('Štatutárny orgán'),
        members: members
    }
  end

  def self.extract_audit_committee
    members = []
    @page.xpath("//table[not(ancestor::table)]/tr[td/span[@class='tl' and contains(text(), 'Kontrolná komisia')]]/td[2]/table").each do |member|
      person = member.xpath(".//br[1]/preceding-sibling::span/text()").to_s.strip.split.join(' ')
      other = member.xpath(".//br[1]/following-sibling::span/text()")
      since = ''


      if other[-1].to_s.match(/.*Vznik funkcie.*/)
        since = other[-1].to_s.gsub('Vznik funkcie:','').strip.split.join(' ')
        other.pop
      end

      address = build_address(other)

      members << {
          :person => person,
          :since => convert_to_date_format(since),
          :address => address
      }
    end

    return members
  end

  def self.convert_to_date_format(date)
    if date == ""
      return nil
    end

    date = date.split('.').map do |item|
      item.strip.rjust(2, "0")
    end

    date.join('/')
  end

  def self.remove_whitespaces(str)
    return str.split.join('')
  end

  def self.extract_attributes(doc, page_id, court_id)
    @page = Nokogiri::HTML(doc)

    if is_correct?

      result = { :pageId => page_id,
                :courtId => court_id,
                :section => process_string(@page.xpath("//table[not(ancestor::table)]/tr/td[span[@class='tl' and contains(text(), 'Oddiel')]]/span[2]/text()")),
                :businessName => extract_basic_attribute('Obchodné meno'),
                :address => build_address(@page.xpath("//table[not(ancestor::table)]/tr[td/span[@class='tl' and contains(text(), 'Sídlo')]]/td[2]/table[1]/tr[1]/td[1]/span/text()")),
                :ico => remove_whitespaces(extract_basic_attribute('IČO')),
                :dateOfEntry => convert_to_date_format(extract_basic_attribute('Deň zápisu')),
                :legalForm => extract_basic_attribute('Právna forma'),
                :businessActivities => extract_basic_list('Predmet činnosti'),
                :companions => extract_companions,
                :eachMemberContribution => extract_each_member_contribution,
                :dateOfDeletion => convert_to_date_format(extract_basic_attribute('Deň výmazu')),
                :deletionReason => extract_basic_attribute('Dôvod výmazu'),
                :capital => extract_capital,
                :statutoryAuthority => extract_statutory_authority,
                :actingInCompanyName => extract_basic_attribute('Konanie menom spoločnosti') != "" ? extract_basic_attribute('Konanie menom spoločnosti') : extract_basic_attribute('Konanie'),
                :auditCommittee => extract_audit_committee,
                :basicMemberContribution => extract_basic_member_contribution,
                :otherLegalFacts => extract_basic_list('Ďalšie právne skutočnosti'),
                :dateOfActualization => convert_to_date_format(extract_actualization_date),
                :merge => extract_basic_attribute('Zlúčenie, splynutie, rozdelenie spoločnosti') != "" ? extract_basic_attribute('Zlúčenie, splynutie, rozdelenie spoločnosti') : extract_basic_attribute('Spoločnosť zaniknutá zlúčením, splynutím alebo rozdelením'),
                :cancelledSince => convert_to_date_format(extract_basic_attribute('Spoločnosť zrušená od')),
                :cancellationReason => extract_basic_attribute('Právny dôvod zrušenia'),
      }

        File.open("#{File.expand_path File.dirname(__FILE__)}/result.json",'a') do |f|
          f.puts JSON.pretty_generate(result)
          f.puts ','
        end

        # puts JSON.pretty_generate(result)
    end

  end

end

# load from local file
# doc = File.open("#{File.expand_path File.dirname(__FILE__)}/page.html", 'r').read
# Crawler.extract_attributes(doc, 000000, 0)


# iterate over pageIds and courtIds to download desired pages and extract all relevant attributes
if ARGV.size == 2
  (ARGV[0].to_i..ARGV[1].to_i).each do |page_id|
    (2..9).each do |court_id|
      CrawlerWorker.perform_async(page_id, court_id, 0.5)
    end
  end
end