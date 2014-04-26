class ExamplesController < ApplicationController
  def australian_members_of_parliament
    # Read in MP example data
    all = CSV.read("db/examples/aus_mp_contact_details.csv")[1..-1].map do |m|
      {
        house: m[0],
        aph_id: m[1],
        full_name: m[2],
        electorate: m[3],
        party: m[4],
        profile_page: m[5],
        contact_page: m[6],
        photo_url: m[7],
        email: m[8],
        facebook: m[9],
        twitter: m[10],
        website: m[11]
      }
    end
    @members = all.select{|p| p[:house] == "representatives"}
    @members = @members[0..49]
    render layout: nil
  end
end
