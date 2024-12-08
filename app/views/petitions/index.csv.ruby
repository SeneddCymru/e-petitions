csv_builder = lambda do |csv|
  csv << ['Petition', 'URL', 'State', 'Signatures Count', 'Created At', 'Opened At', 'Closed At', 'Topics']

  @petitions.find_each do |petition|
    csv << [
      csv_escape(petition.action),
      petition_url(petition),
      petition.state,
      petition.signature_count,
      csv_date_format(petition.created_at),
      csv_date_format(petition.opened_at),
      csv_date_format(petition.closed_at),
      topic_list(petition.topics)
    ]
  end
end

CSV.generate(&csv_builder)
