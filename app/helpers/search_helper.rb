module SearchHelper
  def paginate(petitions)
    options = {
      scope: :"petitions.pagination",
      previous_page: petitions.previous_page,
      next_page: petitions.next_page,
      total_pages: petitions.total_pages,
      previous_link: polymorphic_path(petitions.model, petitions.previous_params),
      next_link: polymorphic_path(petitions.model, petitions.next_params)
    }

    capture do
      concat t(:previous_html, options) unless petitions.first_page?
      concat t(:next_html, options) unless petitions.last_page?
    end
  end

  def filtered_petition_count(petitions)
    options = {
      count: petitions.total_entries,
      num: number_with_delimiter(petitions.total_entries)
    }

    if petitions.search?
      t(:"ui.petitions.search.filtered_result_count", options)
    else
      t(:"ui.petitions.search.filtered_petition_count", options)
    end
  end

  def petition_result_path(petition, options = {})
    if petition.is_a?(Archived::Petition)
      archived_petition_path(petition, options)
    else
      petition_path(petition, options)
    end
  end
end
