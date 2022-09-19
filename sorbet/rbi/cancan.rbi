# typed: false

class ActiveRecord::AssociationRelation < ActiveRecord::Relation
  def accessible_by(ability); end
end
