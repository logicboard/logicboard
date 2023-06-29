var bindings: { id: any; name: string; callback: any }[] = []

export const PubSub = {

  on(id: any, name: string, callback: any) {
    let identifier = typeof (id) == 'string' ? id : id.constructor.name
    this.remove(identifier, name)
    let binding = { id: identifier, name: name, callback: callback }
    bindings.push(binding)
  },

  remove(id: any, name: string) {
    bindings = bindings.filter((binding: { id: any; name: string }) => binding.id != id || binding.name != name)
  },

  dispatch(name: string, props: any | null = null) {
    bindings.forEach((binding) => {
      if (binding.name == name) {
        binding.callback(props)
      }
    })
  },

  all() {
    return bindings
  }
}
