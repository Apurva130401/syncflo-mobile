import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  RefreshControl,
  TouchableOpacity,
  TextInput,
} from 'react-native';
import { useConversations } from '../../hooks/useConversations';
import { ConversationCard } from '../../components/inbox/ConversationCard';
import { EmptyState } from '../../components/common/EmptyState';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { MessageSquare, Search, Mail } from 'lucide-react-native';

export const ConversationListScreen = ({ navigation, route }: any) => {
  const {
    conversations,
    isLoadingConversations,
    fetchConversations,
    selectConversation,
  } = useConversations();

  const assignedToFilter = route?.params?.assignedToFilter;

  const [filter, setFilter] = useState<'all' | 'ai' | 'human' | 'resolved'>(
    'all'
  );
  const [searchQuery, setSearchQuery] = useState('');
  const [unreadOnly, setUnreadOnly] = useState(false);

  useEffect(() => {
    fetchConversations();
  }, []);

  const getFilteredConversations = () => {
    let result = conversations;

    if (assignedToFilter) {
      result = result.filter(
        (c) => c.assignedTo?.toLowerCase() === assignedToFilter.toLowerCase()
      );
    }

    if (filter !== 'all') {
      result = result.filter((c) => c.status === filter);
    }

    if (unreadOnly) {
      result = result.filter((c) => c.unreadCount > 0);
    }

    if (searchQuery.trim().length > 0) {
      const q = searchQuery.toLowerCase();
      result = result.filter(
        (c) =>
          c.contactName?.toLowerCase().includes(q) ||
          c.contactId?.toLowerCase().includes(q)
      );
    }

    return result;
  };

  const handleCardPress = (id: string) => {
    selectConversation(id);
    navigation.navigate('ChatThread', { conversationId: id });
  };

  const renderFilterButton = (
    type: 'all' | 'ai' | 'human' | 'resolved',
    label: string
  ) => {
    const isActive = filter === type;
    return (
      <TouchableOpacity
        activeOpacity={0.8}
        onPress={() => setFilter(type)}
        style={[styles.filterTab, isActive && styles.filterTabActive]}
      >
        <Text style={[styles.filterText, isActive && styles.filterTextActive]}>
          {label}
        </Text>
      </TouchableOpacity>
    );
  };

  if (isLoadingConversations && conversations.length === 0) {
    return <LoadingSpinner fullScreen message="Fetching conversations..." />;
  }

  const filteredData = getFilteredConversations();

  return (
    <View style={styles.container}>
      {/* Search & Toggle Bar */}
      <View style={styles.headerControls}>
        <View style={styles.searchWrapper}>
          <Search size={18} color={colors.textMuted} style={styles.searchIcon} />
          <TextInput
            placeholder="Search name or phone..."
            placeholderTextColor={colors.textMuted}
            value={searchQuery}
            onChangeText={setSearchQuery}
            style={styles.searchInput}
            autoCapitalize="none"
            autoCorrect={false}
          />
        </View>
        <TouchableOpacity
          activeOpacity={0.8}
          onPress={() => setUnreadOnly(!unreadOnly)}
          style={[styles.unreadToggle, unreadOnly && styles.unreadToggleActive]}
        >
          <Mail size={16} color={unreadOnly ? colors.background : colors.primary} />
          <Text
            style={[
              styles.unreadToggleText,
              unreadOnly && styles.unreadToggleTextActive,
            ]}
          >
            Unread
          </Text>
        </TouchableOpacity>
      </View>

      {assignedToFilter && (
        <View style={styles.filterInfoBanner}>
          <Text style={styles.filterInfoText}>
            Showing chats assigned to: <Text style={styles.filterInfoValue}>{assignedToFilter}</Text>
          </Text>
          <TouchableOpacity
            activeOpacity={0.7}
            onPress={() => navigation.setParams({ assignedToFilter: undefined })}
            style={styles.clearFilterBtn}
          >
            <Text style={styles.clearFilterText}>Clear</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* Tabs Filter Bar */}
      <View style={styles.filterBar}>
        {renderFilterButton('all', 'All')}
        {renderFilterButton('ai', 'AI')}
        {renderFilterButton('human', 'Human')}
        {renderFilterButton('resolved', 'Closed')}
      </View>

      {/* Conversations List */}
      <FlatList
        data={filteredData}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <ConversationCard
            conversation={item}
            onPress={() => handleCardPress(item.id)}
          />
        )}
        refreshControl={
          <RefreshControl
            refreshing={isLoadingConversations}
            onRefresh={fetchConversations}
            tintColor={colors.primary}
            colors={[colors.primary]}
          />
        }
        ListEmptyComponent={
          <EmptyState
            title="No conversations found"
            description={
              unreadOnly
                ? 'No unread messages found matching your filters.'
                : searchQuery
                ? `No conversations match "${searchQuery}".`
                : filter === 'all'
                ? 'Your inbox is clear! WhatsApp messages will appear here.'
                : `No conversations in status "${filter}".`
            }
            icon={<MessageSquare size={36} color={colors.textMuted} />}
            actionTitle="Refresh"
            onActionPress={fetchConversations}
          />
        }
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  headerControls: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.md,
    paddingTop: spacing.sm,
    paddingBottom: spacing.xs,
    backgroundColor: colors.surface,
  },
  searchWrapper: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surfaceLight,
    borderRadius: 8,
    paddingHorizontal: spacing.sm,
    height: 40,
    marginRight: spacing.sm,
  },
  searchIcon: {
    marginRight: spacing.xs,
  },
  searchInput: {
    flex: 1,
    color: colors.text,
    fontSize: typography.fontSizes.sm,
    padding: 0, // Reset default Android paddings
  },
  unreadToggle: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surfaceLight,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    paddingHorizontal: spacing.sm,
    height: 40,
  },
  unreadToggleActive: {
    backgroundColor: colors.primary,
    borderColor: colors.primary,
  },
  unreadToggleText: {
    marginLeft: 6,
    color: colors.primary,
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.weights.bold,
  },
  unreadToggleTextActive: {
    color: colors.background,
  },
  filterBar: {
    flexDirection: 'row',
    backgroundColor: colors.surface,
    paddingHorizontal: spacing.md,
    paddingBottom: spacing.sm,
    borderBottomWidth: 1,
    borderColor: colors.border,
  },
  filterTab: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 6,
    borderRadius: 6,
    marginHorizontal: 2,
  },
  filterTabActive: {
    backgroundColor: colors.surfaceLight,
  },
  filterText: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.weights.medium,
  },
  filterTextActive: {
    color: colors.primary,
    fontWeight: typography.weights.bold,
  },
  filterInfoBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: 'rgba(245, 158, 11, 0.12)',
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.xs,
    borderColor: 'rgba(245, 158, 11, 0.25)',
    borderBottomWidth: 1,
  },
  filterInfoText: {
    color: colors.text,
    fontSize: typography.fontSizes.xs,
  },
  filterInfoValue: {
    color: colors.primary,
    fontWeight: typography.weights.bold,
  },
  clearFilterBtn: {
    paddingVertical: 2,
    paddingHorizontal: spacing.sm,
    backgroundColor: colors.surfaceLight,
    borderRadius: 4,
  },
  clearFilterText: {
    color: colors.text,
    fontSize: 10,
    fontWeight: typography.weights.bold,
  },
});

export default ConversationListScreen;
