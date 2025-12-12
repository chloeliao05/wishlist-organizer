class PagesController < ApplicationController
  def homepage
    if current_user == nil
      redirect_to("/users/sign_in")
      return
    end

    matching_items = Item.where({ :user_id => current_user.id })
    @list_of_items = matching_items.order({ :created_at => :desc })

    matching_tags = Tag.where({ :user_id => current_user.id })
    @list_of_tags = matching_tags.order({ :name => :asc })

    render({ :template => "page_templates/homepage" })
  end
end
