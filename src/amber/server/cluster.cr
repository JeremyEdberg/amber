module Amber
  class Cluster
    def self.env_hash
      @@env_hash ||= begin
        env = ENV.to_h
        env["FORKED"] = "1"
        env["AMBER_ENV"] = Amber.env.to_s
      end
    end

    def self.fork
      Process.fork { Process.run(PROGRAM_NAME, nil, env_hash, true, false, input: Process::Redirect::Inherit, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit) }
    end

    def self.master?
      (ENV["FORKED"]? || "0") == "0"
    end

    def self.worker?
      (ENV["FORKED"]? || "0") == "1"
    end
  end
end
