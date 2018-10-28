module Dodo
  module Scalable
    def cram
      @cram ||= @opts.fetch(:scale) {  @opts.fetch(:cram) { 1 } }.ceil
    end

    def stretch
      @stretch ||= @opts.fetch(:scale) { @opts.fetch(:stretch) { 1 } }
    end
  end
end