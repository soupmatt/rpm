# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

# This module builds the data structures necessary to create a Span
# event for a segment.

require 'new_relic/agent/payload_metric_mapping'
require 'new_relic/agent/distributed_trace_payload'

module NewRelic
  module Agent
    module SpanEventPrimitive
      include NewRelic::Coerce
      extend self

      # Strings for static keys of the event structure
      TYPE_KEY           = 'type'.freeze
      TRACE_ID_KEY       = 'traceId'.freeze
      GUID_KEY           = 'guid'.freeze
      PARENT_ID_KEY      = 'parentId'.freeze
      GRANDPARENT_ID_KEY = 'grandparentId'.freeze
      ROOT_SPAN_ID_KEY   = 'rootSpanId'.freeze
      SAMPLED_KEY        = 'sampled'.freeze
      PRIORITY_KEY       = 'priority'.freeze
      TIMESTAMP_KEY      = 'timestamp'.freeze
      DURATION_KEY       = 'duration'.freeze
      NAME_KEY           = 'name'.freeze
      CATEGORY_KEY       = 'category'.freeze

      # Externals
      EXTERNAL_URI_KEY       = "externalUri".freeze
      EXTERNAL_LIBRARY_KEY   = "externalLibrary".freeze
      EXTERNAL_PROCEDURE_KEY = "externalProcedure".freeze

      # Strings for static values of the event structure
      EVENT_TYPE         = 'Span'.freeze
      GENERIC_CATEGORY   = 'generic'.freeze
      EXTERNAL_CATEGORY  = 'external'.freeze

      # To avoid allocations when we have empty custom or agent attributes
      EMPTY_HASH = {}.freeze

      def create(segment)
        intrinsics = intrinsics_for(segment)
        intrinsics[CATEGORY_KEY] = GENERIC_CATEGORY

        [intrinsics, EMPTY_HASH, EMPTY_HASH]
      end

      def for_external_request_segment(segment)
        intrinsics = intrinsics_for(segment)
        intrinsics[EXTERNAL_URI_KEY]       = segment.uri
        intrinsics[EXTERNAL_LIBRARY_KEY]   = segment.library
        intrinsics[EXTERNAL_PROCEDURE_KEY] =  segment.procedure
        intrinsics[CATEGORY_KEY]           = EXTERNAL_CATEGORY

        [intrinsics, EMPTY_HASH, EMPTY_HASH]
      end

      private

      def intrinsics_for(segment)
        {
          TYPE_KEY           => EVENT_TYPE,
          TRACE_ID_KEY       => segment.transaction.trace_id,
          GUID_KEY           => segment.guid,
          PARENT_ID_KEY      => parent_guid(segment),
          GRANDPARENT_ID_KEY => grandparent_guid(segment),
          ROOT_SPAN_ID_KEY   => segment.transaction.guid,
          SAMPLED_KEY        => segment.transaction.sampled?,
          PRIORITY_KEY       => segment.transaction.priority,
          TIMESTAMP_KEY      => milliseconds_since_epoch(segment),
          DURATION_KEY       => segment.duration,
          NAME_KEY           => segment.name
        }
      end

      def parent_guid(segment)
        segment.parent ? segment.parent.guid : nil
      end

      def grandparent_guid(segment)
        segment.parent && segment.parent.parent && segment.parent.parent.guid
      end

      def milliseconds_since_epoch(segment)
        Integer(segment.start_time.to_f * 1000.0)
      end
    end
  end
end
