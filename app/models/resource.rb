class Resource < ActiveRecord::Base
  include ActiveModel::Validations
  has_many :resource_contexts

  #validates_columns :resource_type
  validates :resource_type, presence: true
  validates_presence_of :value, if: :actionable_url_resource
  validates :label, presence: true
  

  

  # validates_columns :value



  scope :guidance, -> { where(resource_type: 'help_text') }
  scope :actionable_url, -> { where(resource_type: 'actionable_url') }
  scope :suggested_response, -> { where(resource_type: 'suggested_response') }
  scope :example_response, -> { where(resource_type: 'example_response') }

  def actionable_url_resource
  	resource_type == "actionable_url"
  end

  

end

