# frozen_string_literal: true

module Pagination
  extend ActiveSupport::Concern

  private

  def paginate(collection, page: 1, per_page: 20, base_collection: nil)
    page = [page.to_i, 1].max
    per_page = [per_page.to_i, 1].max
    offset = (page - 1) * per_page

    # Use base_collection for count if provided (useful for grouped queries)
    count_collection = base_collection || collection
    total_count = count_collection.unscope(
      :select,
      :group,
      :order,
      :left_joins
    ).count
    total_pages = (total_count.to_f / per_page).ceil

    # Apply pagination
    paginated_items = collection.limit(per_page).offset(offset)

    {
      items: paginated_items,
      meta: {
        current_page: page,
        total_pages: total_pages,
        total_count: total_count,
        per_page: per_page
      }
    }
  end
end
