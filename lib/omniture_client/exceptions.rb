module OmnitureClient
  module Exceptions

    class ClientException < StandardError
      attr_reader :data
      def initialize(data)
        @data = data
        super
      end
    end

    class AuthStrategyNotSupported < ClientException; end
    class ReportException          < ClientException; end
    class RequestInvalid           < ClientException; end
    class ReportNotReady           < ClientException; end
    class TriesExceeded            < ClientException; end
    class ReportNotFound           < ClientException; end
  end
end
