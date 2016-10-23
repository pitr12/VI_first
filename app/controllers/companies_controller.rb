require 'elasticsearch'
require 'will_paginate/collection'
require 'hashie'

class CompaniesController < ApplicationController
  before_filter :set_elastic

  PAGE_SIZE = 10

  def index
    @active_search = params[:search]
    if params[:search]
      query = {
          'multi_match': {
            'query': params[:search],
            'fields': [ "businessName", "ico" ]
          }
      }
    else
      @active_search = nil
      query = { match_all: {} }
    end
    @companies = @client.search index: 'vi', type: 'companies' , body: { query: query, size: PAGE_SIZE, from: (params[:page] ? (params[:page].to_i - 1) * PAGE_SIZE : 0) }
    @total_size = @companies["hits"]["total"].to_i
    process_companies
  end

  def show
    @company = Hashie::Mash.new @client.get index: 'vi', type: 'companies', id: params[:id]
    @original_href = "http://orsr.sk/vypis.asp?ID=#{@company._source.pageId}&SID=#{@company._source.courtId}&P=0"
  end

  private
  def process_companies
    page = params[:page] ? params[:page] : 1
    @companies = WillPaginate::Collection.create(page, PAGE_SIZE) do |pager|
      pager.total_entries = @companies["hits"]["total"].to_i
      pager.replace(@companies["hits"]["hits"].map { |company|
        Hashie::Mash.new company
      })
    end
  end

  def set_elastic
    @client = Elasticsearch::Client.new
  end
end
