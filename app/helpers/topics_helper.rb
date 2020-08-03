module TopicsHelper
  def topic_codes(ids)
    @topic_map ||= Topic.map

    ids.inject([]) do |codes, id|
      if topic = @topic_map[id]
        codes << { code: topic.code, name: topic.name }
      end

      codes
    end.sort
  end
end
