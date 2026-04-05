/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useMemo, useEffect } from 'react';
import { 
  Plus, 
  Trash2, 
  ChevronRight,
  Calendar,
  DollarSign,
  ArrowUpRight,
  ArrowDownLeft,
  Settings,
  CreditCard,
  Wallet,
  History,
  X,
  Edit2,
  LayoutGrid,
  List
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

// --- Types ---

interface Account {
  id: string;
  name: string;
  balance: number;
  type: 'credit' | 'savings' | 'loan' | 'bill';
}

interface PaycheckConfig {
  amount: number;
  frequency: 'weekly' | 'bi-weekly' | 'monthly';
  startDate: string;
}

interface Transaction {
  id: string;
  paycheckId: string;
  accountId: string;
  amount: number;
  date: string;
  note: string;
}

interface PaycheckInstance {
  id: string;
  date: string;
  baseAmount: number;
}

// --- Constants ---

const INITIAL_ACCOUNTS: Account[] = [
  { id: '1', name: "US Altitude Reserve", balance: 0, type: 'credit' },
  { id: '2', name: "AE Blue Cash Preferred", balance: 0, type: 'credit' },
  { id: '3', name: "AE Platinum", balance: 0, type: 'credit' },
  { id: '4', name: "AE Personal Loan", balance: 0, type: 'loan' },
  { id: '5', name: "Apple Card", balance: 0, type: 'credit' },
  { id: '6', name: "DCU Auto Loan", balance: 0, type: 'loan' },
  { id: '7', name: "Wells Fargo ActiveCash", balance: 0, type: 'credit' },
  { id: '8', name: "WAY2SAVE", balance: 0, type: 'savings' },
  { id: '9', name: "DCU Savings", balance: 0, type: 'savings' },
  { id: '10', name: "Chase Southwest", balance: 0, type: 'credit' },
  { id: '11', name: "Chase Prime", balance: 0, type: 'credit' },
  { id: '12', name: "Chase Freedom", balance: 0, type: 'credit' },
  { id: '13', name: "Mr. Cooper", balance: 0, type: 'loan' },
  { id: '14', name: "Wealthfront HYSA", balance: 0, type: 'savings' },
  { id: '15', name: "Robinhood", balance: 0, type: 'savings' },
  { id: '16', name: "OCCU BMW", balance: 0, type: 'loan' },
  { id: '17', name: "NFCU '24 Civic", balance: 0, type: 'loan' },
  { id: '18', name: "BMW Financial", balance: 0, type: 'loan' },
  { id: '19', name: "Robinhood Savings", balance: 0, type: 'savings' },
  { id: '20', name: "Robinhood Gold Card", balance: 0, type: 'credit' },
  { id: '21', name: "Capital One Savings", balance: 0, type: 'savings' },
  { id: '22', name: "Citi Simplicity", balance: 0, type: 'credit' }
];

// --- App Component ---

export default function App() {
  // Persistence/State
  const [paycheckConfig, setPaycheckConfig] = useState<PaycheckConfig>({
    amount: 2500,
    frequency: 'bi-weekly',
    startDate: new Date().toISOString().split('T')[0]
  });

  const [accounts, setAccounts] = useState<Account[]>(INITIAL_ACCOUNTS);
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [showSettings, setShowSettings] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  const [showAccountModal, setShowAccountModal] = useState(false);
  const [editingAccount, setEditingAccount] = useState<Account | null>(null);
  const [selectedPaycheckId, setSelectedPaycheckId] = useState<string | null>(null);

  // Generate Paycheck Instances
  const paycheckInstances = useMemo(() => {
    const instances: PaycheckInstance[] = [];
    const start = new Date(paycheckConfig.startDate);
    
    for (let i = -5; i <= 1; i++) {
      const d = new Date(start);
      if (paycheckConfig.frequency === 'weekly') d.setDate(d.getDate() + (i * 7));
      if (paycheckConfig.frequency === 'bi-weekly') d.setDate(d.getDate() + (i * 14));
      if (paycheckConfig.frequency === 'monthly') d.setMonth(d.getMonth() + i);
      
      instances.push({
        id: `paycheck-${d.getTime()}`,
        date: d.toISOString().split('T')[0],
        baseAmount: paycheckConfig.amount
      });
    }
    return instances.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  }, [paycheckConfig]);

  useEffect(() => {
    if (!selectedPaycheckId && paycheckInstances.length > 0) {
      const today = new Date().toISOString().split('T')[0];
      const current = paycheckInstances.find(p => p.date <= today) || paycheckInstances[0];
      setSelectedPaycheckId(current.id);
    }
  }, [paycheckInstances, selectedPaycheckId]);

  const currentPaycheck = useMemo(() => 
    paycheckInstances.find(p => p.id === selectedPaycheckId), 
  [paycheckInstances, selectedPaycheckId]);

  const currentTransactions = useMemo(() => 
    transactions.filter(t => t.paycheckId === selectedPaycheckId),
  [transactions, selectedPaycheckId]);

  const totalAllocated = useMemo(() => 
    currentTransactions.reduce((sum, t) => sum + t.amount, 0),
  [currentTransactions]);

  const remainingBalance = (currentPaycheck?.baseAmount || 0) - totalAllocated;

  // Handlers
  const handleAddTransaction = (data: Omit<Transaction, 'id' | 'paycheckId'>) => {
    if (!selectedPaycheckId) return;
    const newTx: Transaction = {
      id: crypto.randomUUID(),
      paycheckId: selectedPaycheckId,
      ...data
    };
    setTransactions(prev => [...prev, newTx]);
    setShowAddModal(false);
  };

  const handleDeleteTransaction = (id: string) => {
    setTransactions(prev => prev.filter(t => t.id !== id));
  };

  const handleSaveAccount = (accountData: Omit<Account, 'id'> & { id?: string }) => {
    if (accountData.id) {
      setAccounts(prev => prev.map(a => a.id === accountData.id ? { ...a, ...accountData } as Account : a));
    } else {
      const newAccount: Account = {
        id: crypto.randomUUID(),
        ...accountData
      };
      setAccounts(prev => [...prev, newAccount]);
    }
    setShowAccountModal(false);
    setEditingAccount(null);
  };

  const handleDeleteAccount = (id: string) => {
    setAccounts(prev => prev.filter(a => a.id !== id));
    setTransactions(prev => prev.filter(t => t.accountId !== id));
  };

  return (
    <div className="min-h-screen bg-white text-black font-sans selection:bg-[#00c805] selection:text-white">
      {/* Navigation */}
      <nav className="fixed top-0 left-0 right-0 h-16 bg-white border-b border-gray-100 z-40 px-6 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-[#00c805] rounded-full flex items-center justify-center">
            <DollarSign className="w-5 h-5 text-white" />
          </div>
          <span className="font-bold text-xl tracking-tight">BalanceBook Gold</span>
        </div>
        <div className="flex items-center gap-4">
          <button 
            onClick={() => {
              setEditingAccount(null);
              setShowAccountModal(true);
            }}
            className="p-2 hover:bg-gray-50 rounded-full transition-colors group relative"
            title="Manage Accounts"
          >
            <LayoutGrid className="w-5 h-5 text-gray-500 group-hover:text-[#00c805]" />
          </button>
          <button 
            onClick={() => setShowSettings(true)}
            className="p-2 hover:bg-gray-50 rounded-full transition-colors"
          >
            <Settings className="w-5 h-5 text-gray-500" />
          </button>
        </div>
      </nav>

      <main className="pt-24 pb-32 max-w-4xl mx-auto px-6">
        {/* Portfolio Header */}
        <header className="mb-12">
          <div className="flex items-center gap-2 text-sm font-medium text-gray-500 mb-2">
            <Calendar className="w-4 h-4" />
            <span>Paycheck: {currentPaycheck ? new Date(currentPaycheck.date).toLocaleDateString(undefined, { month: 'long', day: 'numeric', year: 'numeric' }) : 'Loading...'}</span>
          </div>
          <h1 className="text-6xl font-bold tracking-tighter mb-4">
            ${remainingBalance.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </h1>
          <div className="flex items-center gap-2">
            <div className={`flex items-center gap-1 text-sm font-bold ${remainingBalance >= 0 ? 'text-[#00c805]' : 'text-[#ff5000]'}`}>
              {remainingBalance >= 0 ? <ArrowUpRight className="w-4 h-4" /> : <ArrowDownLeft className="w-4 h-4" />}
              <span>
                {paycheckConfig.amount > 0 
                  ? `${Math.abs((remainingBalance / paycheckConfig.amount) * 100).toFixed(2)}%` 
                  : '0%'}
              </span>
            </div>
            <span className="text-sm text-gray-400 font-medium">Remaining from ${currentPaycheck?.baseAmount.toLocaleString()}</span>
          </div>
        </header>

        {/* Paycheck Selector Tabs */}
        <div className="flex gap-4 mb-12 overflow-x-auto pb-2 no-scrollbar">
          {paycheckInstances.map((p) => (
            <button
              key={p.id}
              onClick={() => setSelectedPaycheckId(p.id)}
              className={`px-4 py-2 rounded-full text-sm font-bold whitespace-nowrap transition-all ${
                selectedPaycheckId === p.id 
                  ? 'bg-[#00c805] text-white shadow-lg shadow-[#00c805]/20' 
                  : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
              }`}
            >
              {new Date(p.date).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })}
            </button>
          ))}
        </div>

        {/* Transactions Section */}
        <section>
          <div className="flex items-center justify-between mb-6 border-b border-gray-100 pb-4">
            <h2 className="text-xl font-bold">Allocations</h2>
            <button 
              onClick={() => setShowAddModal(true)}
              className="text-[#00c805] font-bold text-sm hover:opacity-80 transition-opacity flex items-center gap-1"
            >
              <Plus className="w-4 h-4" />
              Add Transaction
            </button>
          </div>

          <div className="space-y-1">
            <AnimatePresence mode="popLayout">
              {currentTransactions.length === 0 ? (
                <motion.div 
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="py-12 text-center text-gray-400 font-medium"
                >
                  No transactions associated with this paycheck.
                </motion.div>
              ) : (
                currentTransactions.map((tx) => {
                  const account = accounts.find(a => a.id === tx.accountId);
                  return (
                    <motion.div
                      key={tx.id}
                      layout
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: 20 }}
                      className="flex items-center justify-between p-4 hover:bg-gray-50 rounded-xl transition-colors group"
                    >
                      <div className="flex items-center gap-4">
                        <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center text-gray-500 group-hover:bg-[#00c805]/10 group-hover:text-[#00c805] transition-colors">
                          <CreditCard className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="font-bold text-sm">{account?.name || 'Unknown Account'}</div>
                          <div className="text-xs text-gray-400 font-medium">{tx.note || 'No note'}</div>
                        </div>
                      </div>
                      <div className="flex items-center gap-6">
                        <div className="text-right">
                          <div className="font-bold text-sm">-${tx.amount.toLocaleString(undefined, { minimumFractionDigits: 2 })}</div>
                          <div className="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Allocated</div>
                        </div>
                        <button 
                          onClick={() => handleDeleteTransaction(tx.id)}
                          className="p-2 text-gray-300 hover:text-[#ff5000] opacity-0 group-hover:opacity-100 transition-all"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </motion.div>
                  );
                })
              )}
            </AnimatePresence>
          </div>
        </section>

        {/* Accounts Summary Section */}
        <section className="mt-16">
          <div className="flex items-center justify-between mb-6 border-b border-gray-100 pb-4">
            <h2 className="text-xl font-bold">Your Accounts & Bills</h2>
            <button 
              onClick={() => {
                setEditingAccount(null);
                setShowAccountModal(true);
              }}
              className="text-[#00c805] font-bold text-sm hover:opacity-80 transition-opacity flex items-center gap-1"
            >
              <Plus className="w-4 h-4" />
              Add Account
            </button>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {accounts.map(acc => (
              <div key={acc.id} className="p-4 bg-gray-50 rounded-2xl border border-gray-100 flex items-center justify-between group">
                <div>
                  <div className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-1">{acc.type}</div>
                  <div className="font-bold text-sm">{acc.name}</div>
                  <div className="text-xs text-gray-500 mt-1">Starting: ${acc.balance.toLocaleString()}</div>
                </div>
                <div className="flex items-center gap-2">
                  <button 
                    onClick={() => {
                      setEditingAccount(acc);
                      setShowAccountModal(true);
                    }}
                    className="p-2 text-gray-300 hover:text-black transition-colors"
                  >
                    <Edit2 className="w-4 h-4" />
                  </button>
                  <button 
                    onClick={() => handleDeleteAccount(acc.id)}
                    className="p-2 text-gray-300 hover:text-[#ff5000] transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </section>
      </main>

      {/* Add Transaction Modal */}
      <AnimatePresence>
        {showAddModal && (
          <>
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowAddModal(false)}
              className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50"
            />
            <motion.div 
              initial={{ y: '100%' }}
              animate={{ y: 0 }}
              exit={{ y: '100%' }}
              transition={{ type: 'spring', damping: 25, stiffness: 200 }}
              className="fixed bottom-0 left-0 right-0 bg-white rounded-t-[2.5rem] z-50 p-8 max-w-2xl mx-auto shadow-2xl"
            >
              <div className="flex items-center justify-between mb-8">
                <h2 className="text-2xl font-bold">Add Transaction</h2>
                <button onClick={() => setShowAddModal(false)} className="p-2 hover:bg-gray-100 rounded-full">
                  <X className="w-6 h-6" />
                </button>
              </div>
              
              <AddTransactionForm 
                accounts={accounts} 
                onAdd={handleAddTransaction} 
              />
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Account Modal (Add/Edit) */}
      <AnimatePresence>
        {showAccountModal && (
          <>
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => {
                setShowAccountModal(false);
                setEditingAccount(null);
              }}
              className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50"
            />
            <motion.div 
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-white rounded-[2rem] z-50 p-8 w-full max-w-md shadow-2xl"
            >
              <div className="flex items-center justify-between mb-8">
                <h2 className="text-2xl font-bold">{editingAccount ? 'Edit Account' : 'New Account'}</h2>
                <button onClick={() => {
                  setShowAccountModal(false);
                  setEditingAccount(null);
                }} className="p-2 hover:bg-gray-100 rounded-full">
                  <X className="w-6 h-6" />
                </button>
              </div>
              
              <AccountForm 
                initialData={editingAccount || undefined}
                onSave={handleSaveAccount} 
              />
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Settings Modal */}
      <AnimatePresence>
        {showSettings && (
          <>
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowSettings(false)}
              className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50"
            />
            <motion.div 
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-white rounded-[2rem] z-50 p-8 w-full max-w-md shadow-2xl"
            >
              <div className="flex items-center justify-between mb-8">
                <h2 className="text-2xl font-bold">Paycheck Settings</h2>
                <button onClick={() => setShowSettings(false)} className="p-2 hover:bg-gray-100 rounded-full">
                  <X className="w-6 h-6" />
                </button>
              </div>
              
              <div className="space-y-6">
                <div className="space-y-2">
                  <label className="text-xs font-bold text-gray-400 uppercase tracking-widest">Base Amount</label>
                  <div className="relative">
                    <span className="absolute left-4 top-1/2 -translate-y-1/2 font-bold text-gray-400">$</span>
                    <input 
                      type="number"
                      className="w-full bg-gray-50 border-none rounded-2xl p-4 pl-8 font-bold focus:ring-2 focus:ring-[#00c805] transition-all"
                      value={paycheckConfig.amount}
                      onChange={(e) => setPaycheckConfig(prev => ({ ...prev, amount: Number(e.target.value) }))}
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <label className="text-xs font-bold text-gray-400 uppercase tracking-widest">Frequency</label>
                  <div className="grid grid-cols-3 gap-2">
                    {(['weekly', 'bi-weekly', 'monthly'] as const).map(f => (
                      <button
                        key={f}
                        onClick={() => setPaycheckConfig(prev => ({ ...prev, frequency: f }))}
                        className={`py-3 rounded-xl text-xs font-bold capitalize transition-all ${
                          paycheckConfig.frequency === f 
                            ? 'bg-black text-white' 
                            : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
                        }`}
                      >
                        {f}
                      </button>
                    ))}
                  </div>
                </div>

                <div className="space-y-2">
                  <label className="text-xs font-bold text-gray-400 uppercase tracking-widest">Next Pay Date</label>
                  <input 
                    type="date"
                    className="w-full bg-gray-50 border-none rounded-2xl p-4 font-bold focus:ring-2 focus:ring-[#00c805] transition-all"
                    value={paycheckConfig.startDate}
                    onChange={(e) => setPaycheckConfig(prev => ({ ...prev, startDate: e.target.value }))}
                  />
                </div>

                <button 
                  onClick={() => setShowSettings(false)}
                  className="w-full bg-[#00c805] text-white py-4 rounded-2xl font-bold hover:bg-[#00ab04] transition-colors shadow-lg shadow-[#00c805]/20"
                >
                  Save Changes
                </button>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  );
}

// --- Sub-components ---

function AddTransactionForm({ accounts, onAdd }: { accounts: Account[], onAdd: (data: any) => void }) {
  const [amount, setAmount] = useState('');
  const [accountId, setAccountId] = useState(accounts[0]?.id || '');
  const [note, setNote] = useState('');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!amount || Number(amount) <= 0 || !accountId) return;
    onAdd({
      amount: Number(amount),
      accountId,
      note,
      date
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="space-y-2">
          <label className="text-xs font-bold text-gray-400 uppercase tracking-widest">Amount</label>
          <div className="relative">
            <span className="absolute left-4 top-1/2 -translate-y-1/2 font-bold text-gray-400">$</span>
            <input 
              autoFocus
              type="number"
              step="0.01"
              placeholder="0.00"
              className="w-full bg-gray-50 border-none rounded-2xl p-4 pl-8 font-bold text-xl focus:ring-2 focus:ring-[#00c805] transition-all"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
            />
          </div>
        </div>

        <div className="space-y-2">
          <label className="text-xs font-bold text-gray-400 uppercase tracking-widest">Target Account</label>
          <select 
            className="w-full bg-gray-50 border-none rounded-2xl p-4 font-bold focus:ring-2 focus:ring-[#00c805] transition-all appearance-none"
            value={accountId}
            onChange={(e) => setAccountId(e.target.value)}
          >
            {accounts.map(acc => (
              <option key={acc.id} value={acc.id}>{acc.name}</option>
            ))}
          </select>
        </div>
      </div>

      <div className="space-y-2">
        <label className="text-xs font-bold text-gray-400 uppercase tracking-widest">Note</label>
        <input 
          type="text"
          placeholder="What is this for?"
          className="w-full bg-gray-50 border-none rounded-2xl p-4 font-medium focus:ring-2 focus:ring-[#00c805] transition-all"
          value={note}
          onChange={(e) => setNote(e.target.value)}
        />
      </div>

      <button 
        type="submit"
        className="w-full bg-black text-white py-5 rounded-2xl font-bold hover:bg-gray-800 transition-colors"
      >
        Confirm Allocation
      </button>
    </form>
  );
}

function AccountForm({ initialData, onSave }: { initialData?: Account, onSave: (data: any) => void }) {
  const [name, setName] = useState(initialData?.name || '');
  const [balance, setBalance] = useState(initialData?.balance.toString() || '0');
  const [type, setType] = useState<Account['type']>(initialData?.type || 'credit');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name) return;
    onSave({
      id: initialData?.id,
      name,
      balance: Number(balance),
      type
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div className="space-y-2">
        <label className="text-xs font-bold text-gray-400 uppercase tracking-widest">Account Name</label>
        <input 
          autoFocus
          type="text"
          placeholder="e.g. Phone Bill, Savings, etc."
          className="w-full bg-gray-50 border-none rounded-2xl p-4 font-bold focus:ring-2 focus:ring-[#00c805] transition-all"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-xs font-bold text-gray-400 uppercase tracking-widest">Starting Balance</label>
          <div className="relative">
            <span className="absolute left-4 top-1/2 -translate-y-1/2 font-bold text-gray-400">$</span>
            <input 
              type="number"
              className="w-full bg-gray-50 border-none rounded-2xl p-4 pl-8 font-bold focus:ring-2 focus:ring-[#00c805] transition-all"
              value={balance}
              onChange={(e) => setBalance(e.target.value)}
            />
          </div>
        </div>
        <div className="space-y-2">
          <label className="text-xs font-bold text-gray-400 uppercase tracking-widest">Type</label>
          <select 
            className="w-full bg-gray-50 border-none rounded-2xl p-4 font-bold focus:ring-2 focus:ring-[#00c805] transition-all appearance-none"
            value={type}
            onChange={(e) => setType(e.target.value as any)}
          >
            <option value="credit">Credit Card</option>
            <option value="savings">Savings</option>
            <option value="loan">Loan</option>
            <option value="bill">Recurring Bill</option>
          </select>
        </div>
      </div>

      <button 
        type="submit"
        className="w-full bg-black text-white py-4 rounded-2xl font-bold hover:bg-gray-800 transition-colors"
      >
        {initialData ? 'Save Changes' : 'Create Account'}
      </button>
    </form>
  );
}
