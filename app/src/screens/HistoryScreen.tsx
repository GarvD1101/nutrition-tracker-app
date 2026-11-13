import React from 'react';
import { StyleSheet, Text, View } from 'react-native';

export const HistoryScreen: React.FC = () => {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>History Screen Placeholder</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#ffffff',
  },
  text: {
    fontSize: 18,
    color: '#374151',
  },
});
