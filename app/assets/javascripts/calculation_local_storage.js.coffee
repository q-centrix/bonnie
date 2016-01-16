@CalculationLocalStorage = class CalculationLocalStorage

  # Use a combination of measure id, population index, and patient id to create a cache key
  # Design note: We could use the caching approach of including dates in the key, but that would cause the
  # cache to fill faster and approaches for removing expired items to make room add complication
  @cacheKey: (population, patient) -> "#{population.measure().id}/#{population.get('index')}/#{patient.id}/"

  # Use a combination of the dates the measure and patient were updated for determining validity
  @validationKey: (population, patient) -> "#{population.measure().get('updated_at')}/#{patient.get('updated_at')}"

  # If we're building a patient in the patient builder, it's difficult to create the cache key because 1) the
  # patient won't have an updated_at value and 2) a cloned patient won't have an ID; additionally, it doesn't
  # actually buy us much to cache calculation results as we build the patient; so, don't cache!
  @cachable: (patient) -> patient.id? && patient.get('updated_at')?

  @store: (population, patient, result) ->
    # Assertion to check: measure updated_at changes if calculation code is regenerated

    # Only store a result if it's cachable based on the patient
    console.log "CACHE NON-WRITE: UNCACHABLE" unless @cachable(patient)
    return unless @cachable(patient)

    # Generate a key for caching and another for testing validity
    cacheKey = @cacheKey(population, patient)
    validationKey = @validationKey(population, patient)

    # Store the result with the validationKey
    storageObject = validationKey: validationKey, result: result
    try
      # Store the result, stringifying and compressing it to maximize use of limited local storage size
      # Design note: We could just compressing the result, so checking the validity key later would be faster,
      # but that may not matter if we're getting mostly cache hits
      console.log "CACHE WRITE"
      localStorage.setItem(cacheKey, LZString.compress(JSON.stringify(storageObject)))
    catch error
      # An error likely means the storage is full, in that case we delete a random item (if present) and try
      # again (via recursion to make the error handling simpler). The goal for deleting is to eventually clear
      # out items that are no longer needed, so it doesn't fill up with no-longer-useful results. We could do
      # this more efficiently by tracking LRU, but that turns out to be somewhat complex and this approach may
      # be sufficient
      return if localStorage.length == 0
      randomIndex = Math.floor(Math.random() * localStorage.length)
      console.log "CACHE FULL, DELETING #{randomIndex}"
      localStorage.removeItem(localStorage.key(randomIndex))
      @store(population, patient, result)

  @retrieve: (population, patient) ->

    # Only try to retrieve a result if it would have been cachable based on the patient
    console.log "CACHE NON-READ: UNCACHABLE" unless @cachable(patient)
    return unless @cachable(patient)

    # Calculate the cache key and see if we have a stored result to (possibly) return
    cacheKey = @cacheKey(population, patient)
    storageObject = localStorage.getItem(cacheKey)
    console.log "CACHE MISS" unless storageObject
    return unless storageObject

    # Re-constitute result and test if still valid, based on patient and measure timestamps; return result if
    # valid, otherwise delete expired result and return nothing (which will force re-calculation to happen)
    storageObject = JSON.parse(LZString.decompress(storageObject))
    validationKey = @validationKey(population, patient)
    if storageObject.validationKey == validationKey
      console.log "CACHE HIT"
      return storageObject.result
    else
      console.log "CACHE EXPIRED"
      localStorage.removeItem(cacheKey)
      return
