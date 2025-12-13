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

    if the_item.valid?
      the_item.save

      raw = params.fetch("query_tag_names", "")
      pieces = raw.split(",")

      pieces.each do |piece|
        name = piece.strip

        if name != ""
          matching_tags = Tag.where({ :user_id => current_user.id, :name => name })
          the_tag = matching_tags.at(0)

          if the_tag == nil
            the_tag = Tag.new
            the_tag.user_id = current_user.id
            the_tag.name = name
            the_tag.save
          end

          existing_links = ItemTag.where({ :item_id => the_item.id, :tag_id => the_tag.id })
          link = existing_links.at(0)

          if link == nil
            link = ItemTag.new
            link.item_id = the_item.id
            link.tag_id = the_tag.id
            link.save
          end
        end
      end

      redirect_to("/", { :notice => "Item created successfully." })
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
