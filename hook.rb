module Captain
  class Hook
    attr_accessor :id
    
    def self.me(hookee,prefix="")
      unless prefix == "" || /_$/.match(prefix)
        prefix += "_"
      end

      @hooks.each_value do |hook|
        Hook.functions_for_hook(hook,hookee,prefix)
      end
    end
    
    def self.functions_for_hook(hook,klass,prefix="")
      [:before,:after].each do |method|
        method_name = "#{prefix}#{method.to_s}_#{hook.id.to_s}"
        klass.send :define_method, method_name do |&block| 
          hook.send(method, &block)
        end
      end
      klass.send :define_method, "#{prefix}trigger_#{hook.id.to_s}", ->(params = {}, &block){ hook.trigger(params, &block)}
    end
    
    def self.register(id)
      Hook.new(id)
    end
    
    def self.add(hook)
      @hooks ||= {}
      if @hooks.include?(hook.id)
        raise "Hook with #{hook.id} already registered"
      end
      @hooks[hook.id] = hook
      eigen_class = class << Hook; self; end
      Hook.functions_for_hook(hook,eigen_class)
    end
    
    def self.before(id,&block)
      @hooks ||= {}
      unless @hooks.include?(id) 
        raise "No hook with id #{id} registered"
      end
      @hooks[id].before(&block)
    end
    
    def self.after(id,&block)
      @hooks ||= {}
      unless  @hooks.include?(id) 
        raise "No hook with id #{id} registered"
      end
      @hooks[id].after(&block)
    end
    
    def self.trigger(id,params={},&block)
      unless @hooks.include?(id) 
        raise "No hook with id #{id} registered"
      end
      @hooks[id].trigger(params,&block)
    end 
    
    def initialize(id)
      @id = id
      @before = []
      @after = []
      Hook.add(self)
    end
    
    def before(&block)
      @before << block
    end
    
    def after(&block)
      @after << block
    end  
    
    def trigger(params = {},&block)
      @before.each do |event|
        event.call(params)
      end
      
      yield params if block_given?
      
      @after.each do |event|
        event.call(params)
      end 
      return params
    end
  end
end
