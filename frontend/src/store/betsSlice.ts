import { createSlice, PayloadAction } from "@reduxjs/toolkit";

type Bet = { roundId: number; amount: string; side: "yes" | "no" };

type BetsState = { userBets: Bet[] };

const initialState: BetsState = { userBets: [] };

const betsSlice = createSlice({
  name: "bets",
  initialState,
  reducers: {
    addUserBet(state, action: PayloadAction<Bet>) {
      state.userBets.push(action.payload);
    },
    clearBets(state) {
      state.userBets = [];
    },
  },
});

export const { addUserBet, clearBets } = betsSlice.actions;
export default betsSlice.reducer;
