class ItemsController < ApplicationController
  def index
    if current_user == nil
      redirect_to("/users/sign_in")
      return
    end

    matching_items = Item.where({ :user_id => current_user.id })
    @list_of_items = matching_items.order({ :created_at => :desc })

    render({ :template => "item_templates/index" })
  end

  def create
  if current_user == nil
    redirect_to("/users/sign_in")
    return
  end

  the_item = Item.new
  the_item.user_id = current_user.id
  the_item.url = params.fetch("query_url")
  the_item.buy_by = params.fetch("query_buy_by", "")
  the_item.notes = params.fetch("query_notes", "")

  # Get item details from ChatGPT
  item_details = get_item_details_from_ai(the_item.url)
  the_item.title = item_details[:title]
  the_item.image_url = item_details[:image_url]
  the_item.price = item_details[:price]
  the_item.currency = item_details[:currency]

  if the_item.valid?
    the_item.save

    selected_tag = params.fetch("query_tag_name", "")

    if selected_tag != ""
      category_name = selected_tag
    else
      category_name = item_details[:category]
    end

    matching_tags = Tag.where({ :user_id => current_user.id, :name => category_name })
    the_tag = matching_tags.at(0)

    if the_tag == nil
      the_tag = Tag.new
      the_tag.user_id = current_user.id
      the_tag.name = category_name
      the_tag.save
    end

    link = ItemTag.new
    link.item_id = the_item.id
    link.tag_id = the_tag.id
    link.save

    redirect_to("/", { :notice => "Item added to #{category_name}!" })
  else
    redirect_to("/", { :alert => the_item.errors.full_messages.to_sentence })
    end
  end
  
  def destroy
  if current_user == nil
    redirect_to("/users/sign_in")
    return
  end

  the_id = params.fetch("id")
  the_item = Item.where({ :id => the_id, :user_id => current_user.id }).at(0)

  if the_item != nil
    matching_item_tags = ItemTag.where({ :item_id => the_item.id })
    matching_item_tags.each do |an_item_tag|
      an_item_tag.destroy
    end

    the_item.destroy
  end

  redirect_to("/categories", { :notice => "Item deleted successfully." })
  end
end
