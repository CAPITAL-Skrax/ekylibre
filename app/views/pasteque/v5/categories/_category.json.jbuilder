json.id category.id.to_s
# json.parent_id nil # See Android app
# json.parentId nil
json.label category.name
json.hasImage category.respond_to? :picture
json.dispOrder 0
