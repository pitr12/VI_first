require 'elasticsearch'
require 'will_paginate/collection'
require 'hashie'

class CompaniesController < ApplicationController
  before_filter :set_elastic

  PAGE_SIZE = 10

  def index
    puts params[:capital].inspect
    @active_search = params[:search]
    @companies = @client.search index: 'vi', type: 'companies' , body: { query: build_query, aggs: get_aggregations, size: PAGE_SIZE, from: (params[:page] ? (params[:page].to_i - 1) * PAGE_SIZE : 0) }
    @aggregations = Hashie::Mash.new @companies["aggregations"]
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
    @client = Elasticsearch::Client.new log:true
  end

  def build_query
    if params[:capital] && params[:allCapital] != '1'
      capital = params[:capital].split(',')
      query = {
          'filtered': {
              'filter': build_search_query(nil),
              'query': {
                  'nested': {
                      'path': "capital",
                      'query': {
                          'bool': {
                              'must': [
                                  {
                                      'range': {
                                          'capital.size': {
                                              'gte': capital[0],
                                              'lte': capital[1]
                                          }
                                      }
                                  }
                              ]
                          }
                      }
                  }
              }
          }
      }
    else
      query = {
          'filtered': {
              'filter': build_search_query(nil)
          }
      }
    end

    return query
  end

  def build_filter_query(ommit)
    result = []
    result << {"terms": {"legalForm": params[:legal_forms]}} if params[:legal_forms] && ommit != 'legal_forms'
    result << {"terms": {"courtId": params[:courts]}} if params[:courts] && ommit != 'courts'
    puts result

    return result
  end

  def build_search_query(ommit)
    if params[:search] && params[:search] != ''
      query = {
        'bool': {
          'should': [
              {
                'match': {
                  'businessName': {
                    'query': params[:search],
                    'operator': 'and',
                    'fuzziness': 2,
                    'boost': 2
                  }
                }
              },
              {
                'match': {
                  'ico': {
                    'query': params[:search],
                    'fuzziness': 2
                  }
                }
              }
          ],
          'must': build_filter_query(ommit)
        }
      }
    else
      query = {
          'bool': {
              'must': build_filter_query(ommit)
          }
      }
    end

    return query
  end

  def restrict_range
    result = []
    if params[:capital]
      result << {
          'range': {
              'capital.size': {
                  'gte': 10,
                  'lte': 1000
              }
          }
      }
    end
    return []
  end

  def get_aggregations
    return {
            'companies': {
                'global': {},
                'aggregations': {
                    'legal_forms': {
                        'filter': build_search_query('legal_forms'),
                        'aggregations': {
                            'filtered_legal_forms': {
                                'terms': {
                                    'field': "legalForm"
                                }
                            }
                        }
                    },
                    'courts': {
                        'filter': build_search_query('courts'),
                        'aggregations': {
                            'filtered_courts': {
                                'terms': {
                                    'field': "courtId"
                                }
                            }
                        }
                    }
                }
            }
        }
  end
end
