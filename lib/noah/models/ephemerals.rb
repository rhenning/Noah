module Noah
  class Ephemeral < Model
    include EphemeralValidations
    include Taggable
    include Linkable
    attribute :path
    attribute :data
    attribute :lifetime

    index :path

    def save
      super
      update_ttl(lifetime) if lifetime
    end

    def validate
      super
      assert_present :path
      assert_unique :path
      assert_not_reserved
    end

    def name
      @name = path
    end

    def to_hash
      h = {:path => path, :data => data, :created_at => created_at, :updated_at => updated_at}
      super.merge(h)
    end

    class << self
    def find_or_create(opts = {})
      begin
        path, data, lifetime = opts[:path], opts[:data], opts[:lifetime]
        find(:path => path).first.nil? ? (obj = new(:path => path)) : (obj = find(:path => path).first)
        obj.data = data
        obj.lifetime = lifetime
        if obj.valid?
          obj.save
        end
        obj
      rescue Exception => e
        e.message
      end
    end
    end

    protected
    def save_hook
      # called after any create,update,delete
      # logic needed to expire any orphaned ephemerals
    end

    private
    def path_protected?(path_part)
      # Check for protected paths in ephemeral nodes
    end

  end

end
