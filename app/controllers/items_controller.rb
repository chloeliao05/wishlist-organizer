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

  def show
  if current_user == nil
    redirect_to("/users/sign_in")
    return
  end

  the_id = params.fetch("path_id")
  @the_item = Item.where({ :id => the_id, :user_id => current_user.id }).at(0)

  if @the_item == nil
    redirect_to("/categories")
    return
  end

  item_tag = ItemTag.where({ :item_id => @the_item.id }).at(0)
  if item_tag != nil
    @the_tag = Tag.where({ :id => item_tag.tag_id }).at(0)
  end

  render({ :template => "item_templates/show" })
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
  the_item.priority = params.fetch("query_priority", "None")

  item_details = get_item_details_from_ai(the_item.url)
  the_item.title = item_details[:title]
  the_item.image_url = item_details[:image_url]
  the_item.price = item_details[:price]
  the_item.currency = item_details[:currency]
  the_item.description = item_details[:description]
  the_item.brand = item_details[:store]

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

  the_id = params.fetch("path_id")
  the_item = Item.where({ :id => the_id, :user_id => current_user.id }).at(0)

  # Find the category before deleting
  category_id = nil
  if the_item != nil
    item_tag = ItemTag.where({ :item_id => the_item.id }).at(0)
    if item_tag != nil
      category_id = item_tag.tag_id
    end

    # Delete associated item_tags
    matching_item_tags = ItemTag.where({ :item_id => the_item.id })
    matching_item_tags.each do |an_item_tag|
      an_item_tag.destroy
    end

    the_item.destroy
  end

  if category_id != nil
    redirect_to("/categories/" + category_id.to_s, { :notice => "Item deleted successfully." })
  else
    redirect_to("/categories", { :notice => "Item deleted successfully." })
  end
  end


  def get_item_details_from_ai(url)
  require "http"
  require "json"

  existing_tags = Tag.where({ :user_id => current_user.id }).pluck(:name)
  
  if existing_tags.any?
    category_list = existing_tags.join(", ")
    category_instruction = "Pick the best category from this list: #{category_list}. If none fit, create a new short category name."
  else
    category_instruction = "Suggest a short category name (1-2 words) like: Clothes, Electronics, Books, Home, Beauty, Sports, Toys, Food, Gifts."
  end

  prompt = "Based on this URL: #{url}

Extract the following information and respond in this exact format:
TITLE: [product name]
PRICE: [number only, no symbols]
CURRENCY: [USD, EUR, etc.]
STORE: [store name like Amazon, Nike, etc.]
CATEGORY: [#{category_instruction}]
DESCRIPTION: [a short 1-2 sentence visual description including color, material, and style]

If you cannot determine something, leave it blank. Respond with ONLY the format above, nothing else."

  api_key = ENV["OPENAI_API_KEY"]

  request_headers_hash = {
    "Authorization" => "Bearer #{ENV.fetch("OPENAI_API_KEY")}",
    "content-type" => "application/json"
  }

  request_body_hash = {
    "model" => "gpt-4.1-nano",
    "messages" => [
      {
        "role" => "user",
        "content" => prompt
      }
    ]
  }

  request_body_json = JSON.generate(request_body_hash)

  raw_response = HTTP.headers(request_headers_hash).post(
    "https://api.openai.com/v1/chat/completions",
    :body => request_body_json
  ).to_s

  parsed_response = JSON.parse(raw_response)

  result = parsed_response.fetch("choices").at(0).fetch("message").fetch("content")

  title = ""
  price = ""
  currency = ""
  store = ""
  category = "Other"
  description = ""

  result.each_line do |line|
    if line.start_with?("TITLE:")
      title = line.sub("TITLE:", "").strip
    elsif line.start_with?("PRICE:")
      price = line.sub("PRICE:", "").strip
    elsif line.start_with?("CURRENCY:")
      currency = line.sub("CURRENCY:", "").strip
    elsif line.start_with?("STORE:")
      store = line.sub("STORE:", "").strip
    elsif line.start_with?("CATEGORY:")
      category = line.sub("CATEGORY:", "").strip
    elsif line.start_with?("DESCRIPTION:")
      description = line.sub("DESCRIPTION:", "").strip
    end
  end

  return { title: title, price: price, currency: currency, category: category, store: store, description: description }
  end
end
