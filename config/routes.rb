Rails.application.routes.draw do
  devise_for :users
  root to: "pages#homepage"

  post("/insert_item", { :controller => "items", :action => "create" })
  get("/items",        { :controller => "items", :action => "index" })
end
