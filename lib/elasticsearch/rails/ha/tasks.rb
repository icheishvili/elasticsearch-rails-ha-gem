# Rake tasks to make parallel indexing and high availability easier.

require 'elasticsearch/rails/ha'

namespace :elasticsearch
  namespace :import

    desc "import records in parallel"
    task :parallel do
      nprocs     = ENV['NPROCS'] || 1
      batch_size = ENV['BATCH']  || 100
      max        = ENV['MAX']    || nil
      klass      = ENV['CLASS']

      indexer = Elasticsearch::Rails::HA::ParallelIndexer.new(
        klass: klass, 
        idx_name: klass.index_name,
        nprocs: nprocs.to_i, 
        batch_size: batch_size.to_i, 
        max: max, 
        force: ENV['FORCE'],
        verbose: !ENV['QUIET']
      )

      indexer.run
    end

    desc "stage an index"
    task :stage
      nprocs     = ENV['NPROCS'] || 1
      batch_size = ENV['BATCH']  || 100 
      max        = ENV['MAX']    || nil 
      klass      = ENV['CLASS']

      stager = Elasticsearch::Rails::HA::IndexStager.new(klass)
      indexer = Elasticsearch::Rails::HA::ParallelIndexer.new(
        klass: klass,    
        idx_name: stager.tmp_index_name,
        nprocs: nprocs.to_i,    
        batch_size: batch_size.to_i,    
        max: max,    
        force: ENV['FORCE'],
        verbose: !ENV['QUIET']
      )   
      indexer.run
      stager.alias_index
      stager.clean_up_old_indices
      puts "[#{Time.now.utc.iso8601}] #{klass} index staged as #{stager.stage_index_name}"
    end

  end
end
