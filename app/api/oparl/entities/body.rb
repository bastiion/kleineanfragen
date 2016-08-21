module OParl
  module Entities
    class Body < Grape::Entity
      expose(:id) { |body| OParl::Routes.oparl_v1_body_url(body: body.key) }
      expose(:type) { |_| 'https://schema.oparl.org/1.0/Body' }
      expose(:system, if: { type: :body_full }) { |_| OParl::Routes.oparl_v1_system_url }
      expose(:shortName) { |body| body.state }
      expose :name
      expose :website
      #expose :equivalent ## TODO

      expose(:organization) { |body| OParl::Routes.oparl_v1_body_organizations_url(body: body.key) }
      expose(:person) { |body| OParl::Routes.oparl_v1_body_people_url(body: body.key) }
      expose(:meeting) { |_| nil } # sorry, we don't provide meetings
      expose(:paper) { |body| OParl::Routes.oparl_v1_body_papers_url(body: body.key) }
      expose(:legislativeTerm, using: OParl::Entities::LegislativeTerm) { |body| body.legislative_terms }

      #expose :classification ## TODO 'Landesparlament', 'Bundestag?'

      expose(:web) { |body| Rails.application.routes.url_helpers.body_url(body) } # equivalent in html

      expose(:created) { |obj| obj.created_at }
      expose(:modified) { |obj| obj.updated_at }
    end
  end
end