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
    @page = params[:page]
    @page = @page ? @page.to_i : 1
    if @page == 1
      @members = @members[0..49]
    elsif @page == 2
      @members = @members[50..99]
    else
      @members = @members[100..149]
    end
    render layout: nil
  end
end
