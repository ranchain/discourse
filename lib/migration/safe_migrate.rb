module Migration; end

class Discourse::InvalidMigration < StandardError; end

class Migration::SafeMigrate

  def self.enable!
    return if PG::Connection.method_defined?(:exec_migrator_unpatched)

    PG::Connection.class_eval do
      alias_method :exec_migrator_unpatched, :exec
      alias_method :async_exec_migrator_unpatched, :async_exec

      def exec(*args, &blk)
        Migration::SafeMigrate.protect!(args[0])
        exec_migrator_unpatched(*args, &blk)
      end

      def async_exec(*args, &blk)
        Migration::SafeMigrate.protect!(args[0])
        async_exec_migrator_unpatched(*args, &blk)
      end
    end
  end

  def self.disable!
    return if !PG::Connection.method_defined?(:exec_migrator_unpatched)
    PG::Connection.class_eval do
      alias_method :exec, :exec_migrator_unpatched
      alias_method :async_exec, :async_exec_migrator_unpatched

      remove_method :exec_migrator_unpatched
      remove_method :async_exec_migrator_unpatched
    end
  end

  def self.protect!(sql)
    if sql =~ /^\s*drop\s+table/i
      $stdout.puts("", <<~STR)
        WARNING
        -------------------------------------------------------------------------------------
        An attempt was made to drop a table with the SQL was disallowed
        SQL used was: '#{sql}'
        Please use the deferred pattrn using Migration::TableDropper in db/seeds to drop
        the table.

        This protection is in place to protect us against dropping tables that are currently
        in use by live applications.
      STR
      raise Discourse::InvalidMigration, "Attempt was made to drop a table"
    end
  end
end
