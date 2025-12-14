Rails.application.routes.draw do
  devise_for :users
  root to: "pages#homepage"

  post("/insert_item", { :controller => "items", :action => "create" })
  get("/items",        { :controller => "items", :action => "index" })
  get("/categories", { :controller => "tags", :action => "index" })
  get("/categories/:id", { :controller => "tags", :action => "show" })
  get("/delete_category/:path_id", { :controller => "tags", :action => "destroy" })
  post("/insert_category", { :controller => "tags", :action => "create" })

end
