class ArchivedMeasuresController < ApplicationController
  
  skip_before_action :verify_authenticity_token, only: [:show, :value_sets]
  
  respond_to :json, :js, :html
  
  def index
    
  end
  
  def show
    skippable_fields = [:map_fns, :record_ids, :measure_attributes]
    @archived_measure = ArchivedMeasure.by_user(current_user).find(params[:id])
    
    @archived_measure_json = MultiJson.encode(@archived_measure.measure_hash.as_json(except: skippable_fields))
    respond_with @archived_measure do |format|
      format.json { render json: @archived_measure_json }
    end
  end
  
end
