module RequestResponseStats
  module Generators
    class CustomizationGenerator < Rails::Generators::Base
      source_root File.expand_path('../../templates', __FILE__)
      desc "Create RequestResponseStats customization files"

      def copy_customization_files
        files_to_generate = [
          "config/initializers/request_response_stats_config.rb",
          "app/controllers/req_res_stat_controller.rb",
          "lib/tasks/move_req_res_cycle_data_from_redis_to_mongo.rake"
        ]
        files_to_generate.each do |file|
          puts "Generating #{file}.."
          just_file_name = file.split("/")[-1]
          copy_file just_file_name, file
        end
      end
    end
  end
end
