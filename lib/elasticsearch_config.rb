#!/usr/bin/env ruby
require File.expand_path('../../config/environment',  __FILE__)
require 'elasticsearch'

class ElasticsearchConfig

  def self.setup(index_name)
    puts 'Setting up elasticsearch environment....'
    client = Elasticsearch::Client.new log: false

    if client.indices.exists? index: index_name
      client.indices.delete index: index_name
    end
    client.indices.create index: index_name,
                          body: {
                              settings: {
                                index: {
                                    max_result_window: 500000
                                },
                                analysis: {
                                    filter: {
                                        sk_SK: {
                                          type: "hunspell",
                                          locale: "sk_SK",
                                          dedup: true,
                                          recursion_level: 0
                                        },
                                        stopwords_SK: {
                                          type: "stop",
                                          stopwords_path: "stop-words/stop-words-slovak.txt",
                                          ignore_case: true
                                        },
                                        autocomplete_filter: {
                                          type:     "edge_ngram",
                                          min_gram: 2,
                                          max_gram: 20
                                        }
                                    },
                                    analyzer: {
                                        slovencina_autocomplete: {
                                            type: "custom",
                                            tokenizer: "standard",
                                            filter: %w(
                                                stopwords_SK
                                                sk_SK
                                                lowercase
                                                stopwords_SK
                                                asciifolding
                                                autocomplete_filter
                                            )
                                        },
                                        default: {
                                            type: "custom",
                                            tokenizer: "standard",
                                            filter: %w(
                                                stopwords_SK
                                                sk_SK
                                                lowercase
                                                stopwords_SK
                                                asciifolding
                                            )
                                        }
                                    }
                                }
                              },
                              mappings: {
                                  companies: {
                                      properties: {
                                          actingInCompanyName: {
                                              type: "string",
                                              index: "not_analyzed"
                                          },
                                          address: {
                                              type: "nested",
                                              properties: {
                                                  city: {
                                                      type: "string",
                                                      analyzer: "slovencina_autocomplete",
                                                      search_analyzer: "default",
                                                      fields: {
                                                          raw: {
                                                              type: "string",
                                                              index: "not_analyzed"
                                                          }
                                                      }
                                                  },
                                                  country: {
                                                      type: "string",
                                                      index: "not_analyzed"
                                                  },
                                                  label: {
                                                      type: "string",
                                                      index: "not_analyzed"
                                                  },
                                                  zip: {
                                                      type: "string",
                                                      index: "not_analyzed"
                                                  }
                                              }
                                          },
                                          auditCommittee: {
                                              type: "nested",
                                              properties: {
                                                  address: {
                                                      type: "nested",
                                                      properties: {
                                                          city: {
                                                              type: "string",
                                                              index: "not_analyzed",
                                                          },
                                                          country: {
                                                              type: "string",
                                                              index: "not_analyzed"
                                                          },
                                                          label: {
                                                              type: "string",
                                                              index: "not_analyzed"
                                                          },
                                                          zip: {
                                                              type: "string",
                                                              index: "not_analyzed"
                                                          }
                                                      }
                                                  },
                                                  person: {
                                                      type: "string",
                                                      index: "not_analyzed"
                                                  },
                                                  since: {
                                                      type: "date",
                                                      format: "dd/MM/yyyy",
                                                      index: "not_analyzed"
                                                  },
                                                  title: {
                                                      type: "string",
                                                      index: "not_analyzed"
                                                  }
                                              }
                                          },
                                          basicMemberContribution: {
                                              type: "nested",
                                              properties: {
                                                  currency: {
                                                      type: "string",
                                                      index: "not_analyzed"
                                                  },
                                                  size: {
                                                      type: "double",
                                                      index: "not_analyzed"
                                                  }
                                              }
                                          },
                                          businessActivities: {
                                              type: "string",
                                              index: "not_analyzed"
                                          },
                                          businessName: {
                                              type: "string",
                                              analyzer: "slovencina_autocomplete",
                                              search_analyzer: "default"
                                          },
                                          cancellationReason: {
                                              type: "string",
                                              index: "not_analyzed"
                                          },
                                          cancelledSince: {
                                              type: "date",
                                              format: "dd/MM/yyyy",
                                              index: "not_analyzed"
                                          },
                                          capital: {
                                              type: "nested",
                                              properties: {
                                                  currency: {
                                                      type: "string",
                                                      index: "not_analyzed"
                                                  },
                                                  size: {
                                                      type: "double",
                                                      index: "not_analyzed"
                                                  }
                                              }
                                          },
                                          companions: {
                                              type: "nested",
                                              properties: {
                                                  address: {
                                                      type: "nested",
                                                      properties: {
                                                          city: {
                                                              type: "string",
                                                              index: "not_analyzed",
                                                          },
                                                          country: {
                                                              type: "string",
                                                              index: "not_analyzed"
                                                          },
                                                          label: {
                                                              type: "string",
                                                              index: "not_analyzed"
                                                          },
                                                          zip: {
                                                              type: "string",
                                                              index: "not_analyzed"
                                                          }
                                                      }
                                                  },
                                                  person: {
                                                      type: "nested",
                                                      properties: {
                                                          firstName: {
                                                              type: "string",
                                                              analyzer: "slovencina_autocomplete",
                                                              search_analyzer: "default"
                                                          },
                                                          lastName: {
                                                              type: "string",
                                                              analyzer: "slovencina_autocomplete",
                                                              search_analyzer: "default"
                                                          }
                                                      }
                                                  },
                                                  title: {
                                                      type: "string",
                                                      index: "not_analyzed"
                                                  }
                                              }
                                          },
                                          courtId: {
                                              type: "string",
                                              index: "not_analyzed"
                                          },
                                          dateOfActualization: {
                                              type: "date",
                                              format: "dd/MM/yyyy",
                                              index: "not_analyzed"
                                          },
                                          dateOfDeletion: {
                                              type: "date",
                                              format: "dd/MM/yyyy",
                                              index: "not_analyzed"
                                          },
                                          dateOfEntry: {
                                              type: "date",
                                              format: "dd/MM/yyyy",
                                              index: "not_analyzed"
                                          },
                                          deletionReason: {
                                              type: "string",
                                              index: "not_analyzed"
                                          },
                                          ico: {
                                              type: "string",
                                              analyzer: "slovencina_autocomplete",
                                              search_analyzer: "default"
                                          },
                                          legalForm: {
                                              type: "string",
                                              index: "not_analyzed"
                                          },
                                          merge: {
                                              type: "string",
                                              index: "not_analyzed"
                                          },
                                          otherLegalFacts: {
                                              type: "string",
                                              index: "not_analyzed"
                                          },
                                          pageId: {
                                              type: "string",
                                              index: "not_analyzed"
                                          },
                                          section: {
                                              "type": "string",
                                              index: "not_analyzed"
                                          },
                                          statutoryAuthority: {
                                              type: "nested",
                                              properties: {
                                                  members: {
                                                      type: "nested",
                                                      properties: {
                                                          address: {
                                                              type: "nested",
                                                              properties: {
                                                                  city: {
                                                                      type: "string",
                                                                      index: "not_analyzed",
                                                                  },
                                                                  country: {
                                                                      type: "string",
                                                                      index: "not_analyzed"
                                                                  },
                                                                  label: {
                                                                      type: "string",
                                                                      index: "not_analyzed"
                                                                  },
                                                                  zip: {
                                                                      type: "string",
                                                                      index: "not_analyzed"
                                                                  }
                                                              }
                                                          },
                                                          person: {
                                                              type: "nested",
                                                              properties: {
                                                                  firstName: {
                                                                      type: "string",
                                                                      analyzer: "slovencina_autocomplete",
                                                                      search_analyzer: "default"
                                                                  },
                                                                  lastName: {
                                                                      type: "string",
                                                                      analyzer: "slovencina_autocomplete",
                                                                      search_analyzer: "default"
                                                                  }
                                                              }
                                                          },
                                                          position: {
                                                              type: "string",
                                                              index: "not_analyzed"
                                                          },
                                                          since: {
                                                              type: "date",
                                                              format: "dd/MM/yyyy",
                                                              index: "not_analyzed"
                                                          },
                                                          title: {
                                                              type: "string",
                                                              index: "not_analyzed"
                                                          }
                                                      }
                                                  },
                                                  type: {
                                                      type: "string",
                                                      index: "not_analyzed"
                                                  }
                                              }
                                          }
                                      }
                                  }
                              }
                          }

    puts 'Complete'
  end

end

# ElasticsearchConfig.setup('vi')