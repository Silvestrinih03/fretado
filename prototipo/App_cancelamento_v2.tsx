import logoImg from "@/imports/logo_fretado.png"
import { useEffect, useState } from "react"
import type { ReactNode } from "react"

// ─── Tokens ───────────────────────────────────────────────────────────────────
const GOLD = "#C9A227"
const DARK = "#1A1A1A"
const MUTED = "#8A8A8A"
const BG = "#F7F6F3"
const CARD = "#FFFFFF"
const BORDER = "#EBEBEA"

// ─── SVG base ─────────────────────────────────────────────────────────────────
function Svg({
  size = 22,
  color = "currentColor",
  sw = 1.8,
  children,
}: {
  size?: number
  color?: string
  sw?: number
  children: ReactNode
}) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke={color}
      strokeWidth={sw}
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      {children}
    </svg>
  )
}

// ─── Icons ────────────────────────────────────────────────────────────────────
const IconHome = ({ active }: { active?: boolean }) => {
  const c = active ? GOLD : MUTED
  return (
    <svg
      width={22}
      height={22}
      viewBox="0 0 24 24"
      fill="none"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path
        d="M3 9.5L12 3l9 6.5V20a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V9.5z"
        stroke={c}
        strokeWidth="1.8"
        fill={active ? c : "none"}
      />
      <path d="M9 21V12h6v9" stroke={active ? CARD : c} strokeWidth="1.8" />
    </svg>
  )
}

const IconTruck = ({ active }: { active?: boolean }) => (
  <Svg color={active ? GOLD : MUTED}>
    <rect x="1" y="4" width="15" height="12" rx="1.5" />
    <path d="M16 8h4.5l2.5 3v5H16V8z" />
    <path d="M1 16h22" />
    <circle cx="5" cy="18" r="2" />
    <circle cx="19" cy="18" r="2" />
  </Svg>
)

const IconCreditCard = ({
  active,
  size = 22,
  color,
}: {
  active?: boolean
  size?: number
  color?: string
}) => {
  const c = color ?? (active ? GOLD : MUTED)
  return (
    <Svg size={size} color={c}>
      <rect x="2" y="5" width="20" height="14" rx="3" />
      <path d="M2 10h20M6 15h3" />
    </Svg>
  )
}

const IconUser = ({
  active,
  size = 22,
  color,
}: {
  active?: boolean
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color ?? (active ? GOLD : MUTED)}>
    <circle cx="12" cy="8" r="4" />
    <path d="M4 20c0-4.4 3.6-8 8-8s8 3.6 8 8" />
  </Svg>
)

const IconPackage = ({
  size = 22,
  color = GOLD,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color}>
    <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" />
    <polyline points="3.27 6.96 12 12.01 20.73 6.96" />
    <line x1="12" y1="22.08" x2="12" y2="12" />
  </Svg>
)

const IconClock = ({
  size = 20,
  color = GOLD,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color}>
    <circle cx="12" cy="12" r="9" />
    <polyline points="12 6 12 12 16 14" />
  </Svg>
)

const IconChevronRight = ({
  size = 16,
  color = GOLD,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color} sw={2.2}>
    <polyline points="9 18 15 12 9 6" />
  </Svg>
)

const IconChevronLeft = ({
  size = 20,
  color = DARK,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color} sw={2.2}>
    <polyline points="15 18 9 12 15 6" />
  </Svg>
)

const IconArrow = ({
  size = 15,
  color = DARK,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color} sw={2.2}>
    <line x1="5" y1="12" x2="19" y2="12" />
    <polyline points="13 5 19 12 13 19" />
  </Svg>
)

const IconRefresh = ({
  size = 16,
  color = GOLD,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color} sw={1.8}>
    <polyline points="23 4 23 10 17 10" />
    <polyline points="1 20 1 14 7 14" />
    <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15" />
  </Svg>
)

const IconRouteEmpty = ({
  size = 28,
  color = GOLD,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color}>
    <circle cx="5" cy="18" r="2.5" fill={color} stroke="none" />
    <circle cx="19" cy="6" r="2.5" fill={color} stroke="none" />
    <path d="M5 15.5V9a4 4 0 0 1 4-4h6.5" />
    <path d="M19 8.5v7a4 4 0 0 1-4 4H8.5" />
  </Svg>
)

const IconCheck = ({
  size = 12,
  color = CARD,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color} sw={2.5}>
    <polyline points="20 6 9 17 4 12" />
  </Svg>
)

const IconX = ({
  size = 12,
  color = MUTED,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color} sw={2.5}>
    <line x1="18" y1="6" x2="6" y2="18" />
    <line x1="6" y1="6" x2="18" y2="18" />
  </Svg>
)

const IconCamera = ({
  size = 14,
  color = DARK,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color} sw={1.6}>
    <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" />
    <circle cx="12" cy="13" r="4" />
  </Svg>
)

const IconLogout = ({
  size = 18,
  color = MUTED,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color}>
    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
    <polyline points="16 17 21 12 16 7" />
    <line x1="21" y1="12" x2="9" y2="12" />
  </Svg>
)

const IconShield = ({
  size = 20,
  color = GOLD,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color}>
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
  </Svg>
)

const IconHelp = ({
  size = 20,
  color = GOLD,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color}>
    <circle cx="12" cy="12" r="9" />
    <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" />
    <line x1="12" y1="17" x2="12.01" y2="17" />
  </Svg>
)

const IconFileText = ({
  size = 20,
  color = GOLD,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color}>
    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
    <polyline points="14 2 14 8 20 8" />
    <line x1="16" y1="13" x2="8" y2="13" />
    <line x1="16" y1="17" x2="8" y2="17" />
  </Svg>
)

const IconPencil = ({
  size = 15,
  color = MUTED,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color}>
    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
  </Svg>
)

const IconEye = ({
  size = 16,
  color = MUTED,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color}>
    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
    <circle cx="12" cy="12" r="3" />
  </Svg>
)

const IconPlus = ({
  size = 18,
  color = CARD,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color} sw={2}>
    <line x1="12" y1="5" x2="12" y2="19" />
    <line x1="5" y1="12" x2="19" y2="12" />
  </Svg>
)

const IconTrash = ({
  size = 15,
  color = MUTED,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color}>
    <polyline points="3 6 5 6 21 6" />
    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
  </Svg>
)

const IconStar = ({
  size = 15,
  color = DARK,
}: {
  size?: number
  color?: string
}) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke={color}
    strokeWidth="1.8"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
  </svg>
)

const IconCalendar = ({
  size = 15,
  color = MUTED,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color}>
    <rect x="3" y="4" width="18" height="18" rx="2" />
    <line x1="16" y1="2" x2="16" y2="6" />
    <line x1="8" y1="2" x2="8" y2="6" />
    <line x1="3" y1="10" x2="21" y2="10" />
  </Svg>
)

const IconMail = ({
  size = 18,
  color = MUTED,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color}>
    <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
    <polyline points="22,6 12,13 2,6" />
  </Svg>
)

const IconLock = ({
  size = 18,
  color = MUTED,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color}>
    <rect x="3" y="11" width="18" height="11" rx="2" />
    <path d="M7 11V7a5 5 0 0 1 10 0v4" />
  </Svg>
)

const IconSearch = ({
  active,
  size = 22,
  color,
}: {
  active?: boolean
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color ?? (active ? GOLD : MUTED)}>
    <circle cx="11" cy="11" r="8" />
    <line x1="21" y1="21" x2="16.65" y2="16.65" />
  </Svg>
)

const IconWallet = ({
  active,
  size = 22,
}: {
  active?: boolean
  size?: number
}) => {
  const c = active ? GOLD : MUTED
  return (
    <Svg size={size} color={c}>
      <rect x="2" y="7" width="20" height="14" rx="3" />
      <path d="M16 7V5a2 2 0 0 0-2-2H8a2 2 0 0 0-2 2v2" />
      <circle cx="16.5" cy="14" r="1.5" fill={c} stroke="none" />
    </Svg>
  )
}

const IconFlag = ({
  size = 14,
  color = CARD,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color}>
    <path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z" />
    <line x1="4" y1="22" x2="4" y2="15" />
  </Svg>
)

const IconAlert = ({
  size = 20,
  color = GOLD,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color} sw={1.9}>
    <path d="M10.3 3.6L1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.6a2 2 0 0 0-3.4 0z" />
    <line x1="12" y1="9" x2="12" y2="13" />
    <line x1="12" y1="17" x2="12.01" y2="17" />
  </Svg>
)

const IconMapPin = ({
  size = 20,
  color = GOLD,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color} sw={1.9}>
    <path d="M21 10c0 7-9 12-9 12S3 17 3 10a9 9 0 1 1 18 0z" />
    <circle cx="12" cy="10" r="3" />
  </Svg>
)

const IconUndo = ({
  size = 20,
  color = GOLD,
}: {
  size?: number
  color?: string
}) => (
  <Svg size={size} color={color} sw={1.9}>
    <polyline points="9 14 4 9 9 4" />
    <path d="M20 20a8 8 0 0 0-8-8H4" />
  </Svg>
)

// ─── Types ────────────────────────────────────────────────────────────────────
type NavId = "home" | "rides" | "payments" | "profile"
type DriverNavId = "home" | "requests" | "wallet" | "profile"
type FilterId = "all" | "active" | "completed" | "cancelled"
type RideStatus = "waiting_accept" | "waiting_start" | "on_way_collect" | "on_way_deliver" | "completed" | "cancelled"
type Ride = {
  id: string
  status: RideStatus
  origin: string
  dest: string
  price: string
  weight: string
  date: string
  originComplement?: string
  originReference?: string
  destinationComplement?: string
  destinationReference?: string
  width?: string
  height?: string
  length?: string
  driver?: {
    name: string
    vehicle: string
    plate: string
    rating: string
    rides: number
  }
}
type CardData = {
  brand: string
  last4: string
  expiry: string
  isDefault: boolean
  shade: string
}
type AppScreen = "login" | "forgot" | "shared_help" | "shared_terms" | "client_home" | "client_dispatch_search" | "client_dispatch_retry" | "client_driver_found" | "client_ride_tracking" | "client_rides_empty" | "client_rides_all" | "client_payments_empty" | "client_payments_cards" | "client_profile" | "client_personal_data" | "client_security" | "driver_home" | "driver_offer" | "driver_rides" | "driver_profile" | "driver_personal_data" | "driver_security"

const FILTER_LABELS: Record<FilterId, string> = {
  all: "Todas",
  active: "Em andamento",
  completed: "Finalizadas",
  cancelled: "Canceladas",
}

const STATUS: Record<RideStatus, {
  badge: string
  dot: string
  bg: string
  border: string
  text: string
  hasCheck: boolean
  hasX: boolean
}> = {
  waiting_accept: {
    badge: "Aguardando aceite",
    dot: GOLD,
    bg: "rgba(201,162,39,0.10)",
    border: "rgba(201,162,39,0.28)",
    text: "#9A7810",
    hasCheck: false,
    hasX: false,
  },
  waiting_start: {
    badge: "Aguardando início",
    dot: DARK,
    bg: "rgba(26,26,26,0.07)",
    border: "rgba(26,26,26,0.15)",
    text: "#3A3A3A",
    hasCheck: false,
    hasX: false,
  },
  on_way_collect: {
    badge: "Em coleta",
    dot: CARD,
    bg: GOLD,
    border: GOLD,
    text: DARK,
    hasCheck: false,
    hasX: false,
  },
  on_way_deliver: {
    badge: "Em entrega",
    dot: CARD,
    bg: GOLD,
    border: GOLD,
    text: DARK,
    hasCheck: false,
    hasX: false,
  },
  completed: {
    badge: "Finalizada",
    dot: CARD,
    bg: DARK,
    border: DARK,
    text: CARD,
    hasCheck: true,
    hasX: false,
  },
  cancelled: {
    badge: "Cancelada",
    dot: "#9A9A9A",
    bg: "rgba(0,0,0,0.05)",
    border: "rgba(0,0,0,0.10)",
    text: "#7A7A7A",
    hasCheck: false,
    hasX: true,
  },
}

// ─── Data ─────────────────────────────────────────────────────────────────────
const RIDES: Ride[] = [
  {
    id: "#29",
    status: "waiting_accept",
    origin: "Rua Um 9, Campinas — SP",
    dest: "Rua Marcos Augusto Pinto 170, Campinas — SP",
    price: "R$ 13,75",
    weight: "10,0 kg",
    date: "30/08/2026",
  },
  {
    id: "#30",
    status: "waiting_start",
    origin: "Av. Brasil 500, São Paulo — SP",
    dest: "Rua das Flores 78, Campinas — SP",
    price: "R$ 45,00",
    weight: "25,5 kg",
    date: "29/08/2026",
  },
  {
    id: "#31",
    status: "on_way_collect",
    origin: "Rua São João 15, Campinas — SP",
    dest: "Av. Paulista 1578, São Paulo — SP",
    price: "R$ 67,50",
    weight: "15,0 kg",
    date: "28/08/2026",
  },
  {
    id: "#32",
    status: "on_way_deliver",
    origin: "Rua Augusta 200, São Paulo — SP",
    dest: "Rua Santa Cruz 88, Campinas — SP",
    price: "R$ 89,00",
    weight: "30,0 kg",
    date: "27/08/2026",
  },
  {
    id: "#28",
    status: "completed",
    origin: "Av. Santos Dumont 110, Campinas — SP",
    dest: "Rua XV de Novembro 45, Campinas — SP",
    price: "R$ 35,00",
    weight: "8,0 kg",
    date: "25/08/2026",
  },
  {
    id: "#27",
    status: "cancelled",
    origin: "Rua Barão de Jaguara 220, Campinas — SP",
    dest: "Av. Souza Campos 900, Campinas — SP",
    price: "R$ 22,00",
    weight: "5,0 kg",
    date: "22/08/2026",
  },
]

const ACTIVE_STATUSES: RideStatus[] = [
  "waiting_accept",
  "waiting_start",
  "on_way_collect",
  "on_way_deliver",
]

const HOME_ACTIVE_RIDE: Ride = {
  id: "#9",
  status: "waiting_start",
  origin: "Rua Um 9, Campinas — São Paulo, 13052-502, Brasil",
  dest: "Rua Marcos Augusto Pinto, Campinas — São Paulo, 13049, Brasil",
  originComplement: "Casa 2",
  originReference: "Portão preto, ao lado da padaria",
  destinationComplement: "Bloco B · Apto 34",
  destinationReference: "Entrada pela portaria principal",
  price: "R$ 12,00",
  weight: "66,0 kg",
  width: "45 cm",
  height: "38 cm",
  length: "62 cm",
  date: "29/09/2026",
  driver: {
    name: "Moreno Antonio",
    vehicle: "Toyota Etios",
    plate: "ABC1D23",
    rating: "4,9",
    rides: 47,
  },
}

const CARDS: CardData[] = [
  {
    brand: "Mastercard",
    last4: "1084",
    expiry: "11/2030",
    isDefault: true,
    shade: "#1A1A1A",
  },
  {
    brand: "Visa",
    last4: "5678",
    expiry: "03/2028",
    isDefault: false,
    shade: "#1E2235",
  },
]

const DRIVER_RIDE: Ride = {
  id: "#33",
  status: "on_way_deliver",
  origin: "Rua Um 9, Campinas — SP",
  dest: "Rua Marcos Augusto Pinto 170, Campinas — SP",
  price: "R$ 14,00",
  weight: "5,0 kg",
  date: "31/08/2026",
}

// ─── StatusBar & DynamicIsland ────────────────────────────────────────────────
function DynamicIsland() {
  return (
    <div
      style={{
        display: "flex",
        justifyContent: "center",
        paddingTop: 12,
        paddingBottom: 2,
      }}
    >
      <div
        style={{ width: 120, height: 34, borderRadius: 20, background: DARK }}
      />
    </div>
  )
}

function StatusBar() {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        padding: "6px 26px 4px",
      }}
    >
      <span
        style={{
          fontSize: 15,
          fontWeight: 600,
          color: DARK,
          letterSpacing: -0.3,
        }}
      >
        9:41
      </span>
      <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
        <div style={{ display: "flex", alignItems: "flex-end", gap: 2 }}>
          {[4, 6, 8, 10].map((h, i) => (
            <div
              key={i}
              style={{
                width: 3,
                height: h,
                borderRadius: 1,
                background: DARK,
                opacity: 0.35 + i * 0.22,
              }}
            />
          ))}
        </div>
        <svg
          width="15"
          height="12"
          viewBox="0 0 24 20"
          fill="none"
          stroke={DARK}
          strokeWidth="2.5"
          strokeLinecap="round"
        >
          <path d="M1 7c3-3.5 7-5.5 11-5.5S20 3.5 23 7" opacity="0.35" />
          <path
            d="M5 11.5c1.9-2.1 4.4-3.2 7-3.2s5.1 1.1 7 3.2"
            opacity="0.65"
          />
          <path d="M9 15.5c.8-.9 1.9-1.5 3-1.5s2.2.6 3 1.5" />
          <circle cx="12" cy="19" r="1.5" fill={DARK} stroke="none" />
        </svg>
        <div style={{ display: "flex", alignItems: "center", gap: 1 }}>
          <div
            style={{
              width: 22,
              height: 11,
              borderRadius: 3,
              border: `1.5px solid ${DARK}`,
              display: "flex",
              alignItems: "center",
              padding: 2,
            }}
          >
            <div
              style={{
                width: "76%",
                height: "100%",
                borderRadius: 1,
                background: DARK,
              }}
            />
          </div>
          <div
            style={{
              width: 2,
              height: 5,
              borderRadius: 1,
              background: DARK,
              opacity: 0.4,
            }}
          />
        </div>
      </div>
    </div>
  )
}

// ─── PhoneFrame ───────────────────────────────────────────────────────────────
function PhoneFrame({
  children,
  label,
}: {
  children: ReactNode
  label?: string
}) {
  return (
    <div style={{ flexShrink: 0 }}>
      {label && (
        <p
          style={{
            textAlign: "center",
            marginBottom: 10,
            fontSize: 11,
            fontWeight: 500,
            color: "rgba(255,255,255,0.38)",
            letterSpacing: "0.02em",
          }}
        >
          {label}
        </p>
      )}
      <div style={{ filter: "drop-shadow(0 28px 56px rgba(0,0,0,0.55))" }}>
        <div
          style={{
            borderRadius: 52,
            padding: 13,
            background: "#242426",
            outline: "1px solid rgba(255,255,255,0.07)",
          }}
        >
          <div
            style={{
              borderRadius: 42,
              overflow: "hidden",
              display: "flex",
              flexDirection: "column",
              width: 390,
              height: 820,
              background: BG,
            }}
          >
            <DynamicIsland />
            <StatusBar />
            {children}
          </div>
        </div>
      </div>
    </div>
  )
}

// ─── BottomNav ────────────────────────────────────────────────────────────────
function BottomNav({
  active,
  onSelect,
}: {
  active: NavId
  onSelect?: (id: NavId) => void
}) {
  const items: Array<{
    id: NavId
    label: string
    render: (a: boolean) => ReactNode
  }> = [
    { id: "home", label: "Início", render: (a) => <IconHome active={a} /> },
    { id: "rides", label: "Corridas", render: (a) => <IconTruck active={a} /> },
    {
      id: "payments",
      label: "Pagamentos",
      render: (a) => <IconCreditCard active={a} />,
    },
    { id: "profile", label: "Perfil", render: (a) => <IconUser active={a} /> },
  ]
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "space-around",
        paddingTop: 12,
        paddingBottom: 24,
        borderTop: `1px solid ${BORDER}`,
        background: CARD,
        flexShrink: 0,
      }}
    >
      {items.map(({ id, label, render }) => {
        const isActive = active === id
        return (
          <button
            key={id}
            onClick={() => onSelect?.(id)}
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 4,
              padding: "0 12px",
              position: "relative",
              background: "none",
              border: "none",
              cursor: "pointer",
            }}
          >
            {isActive && (
              <div
                style={{
                  position: "absolute",
                  top: -12,
                  left: "50%",
                  transform: "translateX(-50%)",
                  width: 20,
                  height: 2.5,
                  borderRadius: 99,
                  background: GOLD,
                }}
              />
            )}
            {render(isActive)}
            <span
              style={{
                fontSize: 10,
                fontWeight: 500,
                color: isActive ? GOLD : "#9E9E9E",
              }}
            >
              {label}
            </span>
          </button>
        )
      })}
    </div>
  )
}

// ─── DriverBottomNav ──────────────────────────────────────────────────────────
function DriverBottomNav({
  active,
  onSelect,
}: {
  active: DriverNavId
  onSelect?: (id: DriverNavId) => void
}) {
  const items: Array<{
    id: DriverNavId
    label: string
    render: (a: boolean) => ReactNode
  }> = [
    { id: "home", label: "Início", render: (a) => <IconHome active={a} /> },
    {
      id: "requests",
      label: "Corridas",
      render: (a) => <IconTruck active={a} />,
    },
    {
      id: "wallet",
      label: "Carteira",
      render: (a) => <IconWallet active={a} />,
    },
    { id: "profile", label: "Perfil", render: (a) => <IconUser active={a} /> },
  ]
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "space-around",
        paddingTop: 12,
        paddingBottom: 24,
        borderTop: `1px solid ${BORDER}`,
        background: CARD,
        flexShrink: 0,
      }}
    >
      {items.map(({ id, label, render }) => {
        const isActive = active === id
        return (
          <button
            key={id}
            onClick={() => onSelect?.(id)}
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 4,
              padding: "0 10px",
              position: "relative",
              background: "none",
              border: "none",
              cursor: "pointer",
            }}
          >
            {isActive && (
              <div
                style={{
                  position: "absolute",
                  top: -12,
                  left: "50%",
                  transform: "translateX(-50%)",
                  width: 20,
                  height: 2.5,
                  borderRadius: 99,
                  background: GOLD,
                }}
              />
            )}
            {render(isActive)}
            <span
              style={{
                fontSize: 10,
                fontWeight: 500,
                color: isActive ? GOLD : "#9E9E9E",
              }}
            >
              {label}
            </span>
          </button>
        )
      })}
    </div>
  )
}

// ─── SecondaryHeader ──────────────────────────────────────────────────────────
function SecondaryHeader({
  title,
  onBack,
}: {
  title: string
  onBack?: () => void
}) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 10,
        padding: "6px 20px 12px",
      }}
    >
      <button
        onClick={onBack}
        style={{
          width: 36,
          height: 36,
          borderRadius: 12,
          background: CARD,
          border: `1px solid ${BORDER}`,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          flexShrink: 0,
          boxShadow: "0 1px 4px rgba(0,0,0,0.06)",
          cursor: "pointer",
        }}
      >
        <IconChevronLeft size={18} color={DARK} />
      </button>
      <h1
        style={{
          fontSize: 17,
          fontWeight: 700,
          color: DARK,
          letterSpacing: -0.3,
        }}
      >
        {title}
      </h1>
    </div>
  )
}

// ─── StatusBadge ─────────────────────────────────────────────────────────────
function StatusBadge({ status }: { status: RideStatus }) {
  const s = STATUS[status]
  return (
    <div
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 5,
        padding: "4px 10px",
        borderRadius: 99,
        background: s.bg,
        border: `1px solid ${s.border}`,
        flexShrink: 0,
      }}
    >
      {s.hasCheck ? (
        <IconCheck size={10} color={s.text} />
      ) : s.hasX ? (
        <IconX size={10} color={s.text} />
      ) : (
        <div
          style={{
            width: 6,
            height: 6,
            borderRadius: 99,
            background: s.dot,
            flexShrink: 0,
          }}
        />
      )}
      <span
        style={{
          fontSize: 10,
          fontWeight: 600,
          color: s.text,
          whiteSpace: "nowrap",
        }}
      >
        {s.badge}
      </span>
    </div>
  )
}

// ─── RideCard ─────────────────────────────────────────────────────────────────
function RideCard({
  ride,
  onCancel,
  onDetails,
}: {
  ride: Ride
  onCancel?: (ride: Ride) => void
  onDetails?: (ride: Ride) => void
}) {
  return (
    <div
      style={{
        background: CARD,
        borderRadius: 16,
        padding: 16,
        border: `1px solid ${BORDER}`,
        boxShadow: "0 1px 6px rgba(0,0,0,0.05)",
      }}
    >
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "flex-start",
          marginBottom: 12,
        }}
      >
        <div>
          <p style={{ fontSize: 14, fontWeight: 700, color: DARK }}>
            Corrida {ride.id}
          </p>
          <p style={{ fontSize: 11, color: MUTED, marginTop: 2 }}>
            {ride.date}
          </p>
        </div>
        <StatusBadge status={ride.status} />
      </div>
      <div style={{ display: "flex", gap: 10, alignItems: "stretch" }}>
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            paddingTop: 2,
            flexShrink: 0,
          }}
        >
          <div
            style={{
              width: 7,
              height: 7,
              borderRadius: 99,
              background: GOLD,
              flexShrink: 0,
            }}
          />
          <div
            style={{
              width: 1,
              flex: 1,
              minHeight: 18,
              background: "rgba(26,26,26,0.12)",
              margin: "3px 0",
            }}
          />
          <div
            style={{
              width: 7,
              height: 7,
              borderRadius: 99,
              background: DARK,
              flexShrink: 0,
            }}
          />
        </div>
        <div
          style={{ flex: 1, display: "flex", flexDirection: "column", gap: 10 }}
        >
          <p style={{ fontSize: 12, color: DARK, lineHeight: "1.4" }}>
            {ride.origin}
          </p>
          <p style={{ fontSize: 12, color: MUTED, lineHeight: "1.4" }}>
            {ride.dest}
          </p>
        </div>
      </div>
      <div
        style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 12 }}
      >
        <div
          style={{
            padding: "4px 8px",
            borderRadius: 6,
            background: BG,
            border: `1px solid ${BORDER}`,
          }}
        >
          <span style={{ fontSize: 11, fontWeight: 600, color: DARK }}>
            {ride.price}
          </span>
        </div>
        <div
          style={{
            padding: "4px 8px",
            borderRadius: 6,
            background: BG,
            border: `1px solid ${BORDER}`,
          }}
        >
          <span style={{ fontSize: 11, color: MUTED }}>{ride.weight}</span>
        </div>
        <div style={{ flex: 1 }} />
        <button
          onClick={() => onDetails?.(ride)}
          style={{
            display: "inline-flex",
            alignItems: "center",
            gap: 2,
            background: "none",
            border: "none",
            cursor: "pointer",
            padding: 0,
          }}
        >
          <span style={{ fontSize: 12, fontWeight: 600, color: GOLD }}>
            Detalhes
          </span>
          <IconChevronRight size={12} color={GOLD} />
        </button>
      </div>
      {onCancel && ACTIVE_STATUSES.includes(ride.status) && (
        <div style={{ marginTop: 13, paddingTop: 12, borderTop: `1px solid ${BORDER}` }}>
          <button
            onClick={() => onCancel(ride)}
            style={{
              width: "100%",
              padding: "11px 12px",
              borderRadius: 12,
              background: "rgba(166,44,44,0.045)",
              border: "1px solid rgba(166,44,44,0.18)",
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 8,
            }}
          >
            <div
              style={{
                width: 22,
                height: 22,
                borderRadius: 8,
                background: "rgba(166,44,44,0.08)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <IconX size={11} color="#A62C2C" />
            </div>
            <span style={{ fontSize: 12, fontWeight: 700, color: "#A62C2C" }}>
              Cancelar corrida
            </span>
          </button>
        </div>
      )}
    </div>
  )
}

// ─── PaymentCardVisual ────────────────────────────────────────────────────────
function PaymentCardVisual({ card }: { card: CardData }) {
  return (
    <div
      style={{
        borderRadius: 16,
        padding: "18px 20px",
        background: `linear-gradient(140deg, ${card.shade} 0%, #2E2E3C 100%)`,
        position: "relative",
        overflow: "hidden",
      }}
    >
      <div
        style={{
          position: "absolute",
          top: -30,
          right: -30,
          width: 140,
          height: 140,
          borderRadius: 70,
          background:
            "radial-gradient(circle, rgba(201,162,39,0.10) 0%, transparent 70%)",
        }}
      />
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 20,
        }}
      >
        <div
          style={{
            width: 36,
            height: 26,
            borderRadius: 4,
            background: "linear-gradient(135deg, #D4A820 0%, #8A6010 100%)",
          }}
        />
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          {card.isDefault && (
            <div
              style={{
                padding: "3px 10px",
                borderRadius: 99,
                background: "rgba(201,162,39,0.18)",
                border: "1px solid rgba(201,162,39,0.32)",
              }}
            >
              <span
                style={{
                  fontSize: 9,
                  fontWeight: 700,
                  color: GOLD,
                  letterSpacing: "0.06em",
                }}
              >
                PADRÃO
              </span>
            </div>
          )}
          <span
            style={{
              fontSize: 14,
              fontWeight: 800,
              color: "rgba(255,255,255,0.82)",
              letterSpacing: "0.04em",
            }}
          >
            {card.brand.toUpperCase()}
          </span>
        </div>
      </div>
      <p
        style={{
          fontSize: 17,
          fontWeight: 600,
          color: "rgba(255,255,255,0.82)",
          letterSpacing: "0.16em",
          marginBottom: 18,
        }}
      >
        •••• •••• •••• {card.last4}
      </p>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "flex-end",
        }}
      >
        <div>
          <p
            style={{
              fontSize: 9,
              color: "rgba(255,255,255,0.38)",
              letterSpacing: "0.06em",
              textTransform: "uppercase",
              marginBottom: 3,
            }}
          >
            Titular
          </p>
          <p
            style={{
              fontSize: 12,
              fontWeight: 600,
              color: "rgba(255,255,255,0.80)",
            }}
          >
            MARIA ANTONIA
          </p>
        </div>
        <div style={{ textAlign: "right" }}>
          <p
            style={{
              fontSize: 9,
              color: "rgba(255,255,255,0.38)",
              letterSpacing: "0.06em",
              textTransform: "uppercase",
              marginBottom: 3,
            }}
          >
            Vence
          </p>
          <p
            style={{
              fontSize: 12,
              fontWeight: 600,
              color: "rgba(255,255,255,0.80)",
            }}
          >
            {card.expiry}
          </p>
        </div>
      </div>
      <div
        style={{
          position: "absolute",
          bottom: 0,
          left: 0,
          right: 0,
          height: 2,
          background: `linear-gradient(90deg, transparent, ${GOLD}, transparent)`,
        }}
      />
    </div>
  )
}

// ─── FormField ────────────────────────────────────────────────────────────────
function FormField({
  label,
  value,
  icon,
  readOnly = false,
}: {
  label: string
  value: string
  icon?: ReactNode
  readOnly?: boolean
}) {
  return (
    <div>
      <p
        style={{
          fontSize: 10,
          fontWeight: 600,
          color: MUTED,
          letterSpacing: "0.07em",
          textTransform: "uppercase",
          marginBottom: 6,
        }}
      >
        {label}
      </p>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          background: CARD,
          border: `1px solid ${BORDER}`,
          borderRadius: 12,
          padding: "12px 14px",
          gap: 8,
        }}
      >
        <p
          style={{ flex: 1, fontSize: 14, color: readOnly ? "#AAAAAA" : DARK }}
        >
          {value}
        </p>
        {icon && icon}
      </div>
    </div>
  )
}

// ─── UserAvatar ───────────────────────────────────────────────────────────────
function UserAvatar({
  size = 64,
  showEdit = false,
  initials = "MA",
}: {
  size?: number
  showEdit?: boolean
  initials?: string
}) {
  return (
    <div
      style={{ position: "relative", width: size, height: size, flexShrink: 0 }}
    >
      <div
        style={{
          width: size,
          height: size,
          borderRadius: size / 2,
          background: DARK,
          border: `2px solid rgba(201,162,39,0.32)`,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <span
          style={{
            fontSize: size * 0.28,
            fontWeight: 700,
            color: GOLD,
            letterSpacing: 1,
          }}
        >
          {initials}
        </span>
      </div>
      {showEdit && (
        <div
          style={{
            position: "absolute",
            bottom: 0,
            right: 0,
            width: 24,
            height: 24,
            borderRadius: 12,
            background: GOLD,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            border: `2px solid ${BG}`,
          }}
        >
          <IconCamera size={12} color={DARK} />
        </div>
      )}
    </div>
  )
}

// ─── QuickCard ────────────────────────────────────────────────────────────────
function QuickCard({
  icon,
  title,
  sub,
  onClick,
}: {
  icon: ReactNode
  title: string
  sub: string
  onClick?: () => void
}) {
  return (
    <button
      onClick={onClick}
      style={{
        background: CARD,
        borderRadius: 16,
        padding: "14px 16px",
        display: "flex",
        alignItems: "center",
        gap: 14,
        border: `1px solid ${BORDER}`,
        boxShadow: "0 1px 6px rgba(0,0,0,0.05)",
        textAlign: "left",
        width: "100%",
        cursor: "pointer",
      }}
    >
      <div
        style={{
          width: 44,
          height: 44,
          borderRadius: 13,
          background: DARK,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          flexShrink: 0,
        }}
      >
        {icon}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <p style={{ fontSize: 14, fontWeight: 600, color: DARK }}>{title}</p>
        <p style={{ fontSize: 12, color: MUTED, marginTop: 2 }}>{sub}</p>
      </div>
      <IconChevronRight size={16} color={GOLD} />
    </button>
  )
}

// ─── ToggleSwitch ─────────────────────────────────────────────────────────────
function ToggleSwitch({
  value,
  onChange,
}: {
  value: boolean
  onChange: (v: boolean) => void
}) {
  return (
    <button
      onClick={() => onChange(!value)}
      style={{
        width: 50,
        height: 28,
        borderRadius: 14,
        position: "relative",
        background: value ? GOLD : "#C8C7C2",
        border: "none",
        cursor: "pointer",
        flexShrink: 0,
      }}
    >
      <div
        style={{
          position: "absolute",
          top: 3,
          width: 22,
          height: 22,
          borderRadius: 11,
          background: CARD,
          boxShadow: "0 1px 4px rgba(0,0,0,0.22)",
          left: value ? 25 : 3,
        }}
      />
    </button>
  )
}

// ─── SCREEN: Home (Cliente) ───────────────────────────────────────────────────
function HomeScreen({
  nav,
  setNav,
  onSolicitarFrete,
  onTrackRide,
  initialActiveRide = false,
}: {
  nav: NavId
  setNav: (n: NavId) => void
  onSolicitarFrete?: () => void
  onTrackRide?: (ride: Ride) => void
  initialActiveRide?: boolean
}) {
  const [showActiveRide, setShowActiveRide] = useState(initialActiveRide)
  const [detailsRide, setDetailsRide] = useState<Ride | null>(null)
  const [cancellationRide, setCancellationRide] = useState<Ride | null>(null)

  return (
    <>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "4px 20px 10px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <img src={logoImg} alt="FreteJá" style={{ width: 36, height: 36, objectFit: "contain", borderRadius: 10 }} />
          <span style={{ fontSize: 21, fontWeight: 800, letterSpacing: -0.5 }}><span style={{ color: DARK }}>Frete</span><span style={{ color: GOLD }}>Já</span></span>
        </div>
        <button onClick={() => setNav("profile")} style={{ width: 40, height: 40, borderRadius: 14, background: DARK, display: "flex", alignItems: "center", justifyContent: "center", border: "none", cursor: "pointer" }}>
          <IconUser size={18} color={CARD} />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto no-scrollbar">
        <div style={{ padding: "2px 20px 24px", display: "flex", flexDirection: "column", gap: 16 }}>
          <div>
            <h1 style={{ fontSize: 30, fontWeight: 800, letterSpacing: -0.8, color: DARK, lineHeight: "1.18" }}>Olá, <span style={{ color: GOLD }}>Maria!</span></h1>
            <p style={{ fontSize: 14, color: MUTED, marginTop: 6, lineHeight: "1.55" }}>Para onde vamos hoje? Encontre fretes rápidos e seguros.</p>
          </div>

          <div style={{ background: DARK, borderRadius: 20, padding: 20 }}>
            <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: 14 }}>
              <div style={{ width: 48, height: 48, borderRadius: 14, background: "rgba(201,162,39,0.11)", border: "1px solid rgba(201,162,39,0.22)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <IconPackage size={22} color={GOLD} />
              </div>
              <IconChevronRight size={18} color="rgba(255,255,255,0.18)" />
            </div>
            <h2 style={{ fontSize: 18, fontWeight: 700, color: CARD, marginBottom: 4 }}>Solicitar Frete</h2>
            <p style={{ fontSize: 13, color: "#686868", lineHeight: "1.55", marginBottom: 16 }}>Precisando de alguém para transportar um produto? Nos fretamos para você.</p>
            <button onClick={onSolicitarFrete} style={{ width: "100%", background: GOLD, borderRadius: 14, padding: "14px 0", display: "flex", alignItems: "center", justifyContent: "center", gap: 8, border: "none", cursor: "pointer" }}>
              <span style={{ fontSize: 13, fontWeight: 700, color: DARK, letterSpacing: "0.08em" }}>SOLICITAR AGORA</span>
              <IconArrow size={14} color={DARK} />
            </button>
          </div>

          <QuickCard icon={<IconClock size={20} color={GOLD} />} title="Histórico de corridas" sub="Ver corridas anteriores e finalizadas" onClick={() => setNav("rides")} />
          <QuickCard icon={<IconCreditCard size={20} color={GOLD} />} title="Métodos de pagamento" sub="Gerenciar cartões para seus fretes" onClick={() => setNav("payments")} />

          <div>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
              <div>
                <h3 style={{ fontSize: 15, fontWeight: 700, color: DARK }}>Corridas em andamento</h3>
                {showActiveRide && <p style={{ fontSize: 10.5, color: MUTED, marginTop: 2 }}>1 corrida ativa</p>}
              </div>
              <button onClick={() => setShowActiveRide(true)} style={{ display: "inline-flex", alignItems: "center", gap: 5, background: "none", border: "none", cursor: "pointer", padding: 0 }}>
                <IconRefresh size={13} color={GOLD} />
                <span style={{ fontSize: 12, fontWeight: 600, color: GOLD }}>Atualizar</span>
              </button>
            </div>

            {!showActiveRide ? (
              <div style={{ background: CARD, borderRadius: 16, padding: 28, display: "flex", flexDirection: "column", alignItems: "center", border: `1px solid ${BORDER}`, boxShadow: "0 1px 6px rgba(0,0,0,0.05)" }}>
                <div style={{ width: 52, height: 52, borderRadius: 26, background: BG, display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 12 }}>
                  <IconRouteEmpty size={26} color={GOLD} />
                </div>
                <p style={{ fontSize: 14, fontWeight: 600, color: DARK, marginBottom: 4 }}>Nenhuma corrida em andamento</p>
                <p style={{ fontSize: 12, color: MUTED, textAlign: "center", lineHeight: "1.5" }}>Toque em “Atualizar” para simular<br />uma corrida ativa no protótipo.</p>
              </div>
            ) : (
              <div style={{ background: CARD, borderRadius: 20, border: `1px solid ${BORDER}`, boxShadow: "0 7px 24px rgba(0,0,0,0.07)", overflow: "hidden" }}>
                <div style={{ height: 4, background: GOLD }} />
                <div style={{ padding: 17 }}>
                  <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 10 }}>
                    <div>
                      <p style={{ fontSize: 10, fontWeight: 700, color: MUTED, letterSpacing: "0.08em" }}>CORRIDA EM ANDAMENTO</p>
                      <p style={{ fontSize: 18, fontWeight: 800, color: DARK, marginTop: 3 }}>Corrida {HOME_ACTIVE_RIDE.id}</p>
                    </div>
                    <StatusBadge status={HOME_ACTIVE_RIDE.status} />
                  </div>

                  <div style={{ display: "flex", gap: 11, marginTop: 16 }}>
                    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", paddingTop: 3 }}>
                      <span style={{ width: 9, height: 9, borderRadius: 9, background: GOLD }} />
                      <span style={{ width: 1, height: 32, background: BORDER, margin: "4px 0" }} />
                      <span style={{ width: 9, height: 9, borderRadius: 9, background: DARK }} />
                    </div>
                    <div style={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column", gap: 13 }}>
                      <div><p style={{ fontSize: 9.5, color: MUTED }}>COLETA</p><p style={{ fontSize: 12, fontWeight: 650, color: DARK, marginTop: 2, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{HOME_ACTIVE_RIDE.origin}</p></div>
                      <div><p style={{ fontSize: 9.5, color: MUTED }}>ENTREGA</p><p style={{ fontSize: 12, color: MUTED, marginTop: 2, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{HOME_ACTIVE_RIDE.dest}</p></div>
                    </div>
                  </div>

                  {HOME_ACTIVE_RIDE.driver && (
                    <div style={{ marginTop: 15, padding: "12px 13px", borderRadius: 14, background: BG, border: `1px solid ${BORDER}`, display: "flex", alignItems: "center", gap: 10 }}>
                      <UserAvatar size={38} initials="MA" />
                      <div style={{ flex: 1 }}>
                        <p style={{ fontSize: 12.5, fontWeight: 700, color: DARK }}>{HOME_ACTIVE_RIDE.driver.name}</p>
                        <p style={{ fontSize: 10.5, color: MUTED, marginTop: 2 }}>{HOME_ACTIVE_RIDE.driver.vehicle} · {HOME_ACTIVE_RIDE.driver.plate}</p>
                      </div>
                      <div style={{ textAlign: "right" }}>
                        <div style={{ display: "flex", alignItems: "center", gap: 4, justifyContent: "flex-end" }}><IconStar size={11} color={GOLD} /><span style={{ fontSize: 10.5, fontWeight: 700, color: DARK }}>{HOME_ACTIVE_RIDE.driver.rating}</span></div>
                        <p style={{ fontSize: 9.5, color: MUTED, marginTop: 2 }}>{HOME_ACTIVE_RIDE.driver.rides} corridas</p>
                      </div>
                    </div>
                  )}

                  <div style={{ display: "flex", gap: 8, marginTop: 14 }}>
                    <div style={{ flex: 1, padding: "10px 11px", borderRadius: 12, background: BG, border: `1px solid ${BORDER}` }}><p style={{ fontSize: 9.5, color: MUTED }}>VALOR</p><p style={{ fontSize: 13, fontWeight: 800, color: DARK, marginTop: 2 }}>{HOME_ACTIVE_RIDE.price}</p></div>
                    <div style={{ flex: 1, padding: "10px 11px", borderRadius: 12, background: BG, border: `1px solid ${BORDER}` }}><p style={{ fontSize: 9.5, color: MUTED }}>CARGA</p><p style={{ fontSize: 13, fontWeight: 800, color: DARK, marginTop: 2 }}>{HOME_ACTIVE_RIDE.weight}</p></div>
                  </div>

                  <button onClick={() => onTrackRide?.(HOME_ACTIVE_RIDE)} style={{ width: "100%", marginTop: 14, padding: "13px 0", borderRadius: 13, background: DARK, color: CARD, border: "none", cursor: "pointer", fontSize: 12.5, fontWeight: 750, display: "flex", alignItems: "center", justifyContent: "center", gap: 7 }}>
                    Acompanhar corrida <IconChevronRight size={13} color={CARD} />
                  </button>
                  <button onClick={() => setDetailsRide(HOME_ACTIVE_RIDE)} style={{ width: "100%", marginTop: 7, padding: "11px 0", borderRadius: 12, background: "transparent", color: GOLD, border: "none", cursor: "pointer", fontSize: 11.5, fontWeight: 700 }}>
                    Ver todos os detalhes
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      <BottomNav active={nav} onSelect={setNav} />
      {detailsRide && <RideDetailsModal ride={detailsRide} onClose={() => setDetailsRide(null)} onTrack={() => { setDetailsRide(null); onTrackRide?.(detailsRide) }} onCancel={() => { setCancellationRide(detailsRide); setDetailsRide(null) }} />}
      {cancellationRide && <CancellationModal ride={cancellationRide} onClose={() => setCancellationRide(null)} />}
    </>
  )
}

// ─── Cancelamento de corrida (Cliente) ─────────────────────────────────────────
type CancellationStage =
  | "request"
  | "waiting_driver"
  | "quote"
  | "success"
  | "declined"

type ReturnDestination = "origin" | "other"

function formatBrl(value: number) {
  return value.toLocaleString("pt-BR", { style: "currency", currency: "BRL" })
}

function parseBrl(value: string) {
  const normalized = value.replace(/[^0-9,]/g, "").replace(",", ".")
  return Number(normalized || 0)
}

function CancellationModal({
  ride,
  onClose,
  initialStage = "request",
}: {
  ride: Ride
  onClose: () => void
  initialStage?: CancellationStage
}) {
  const [stage, setStage] = useState<CancellationStage>(initialStage)
  const [reason, setReason] = useState("")
  const [destination, setDestination] = useState<ReturnDestination>("origin")
  const [otherAddress, setOtherAddress] = useState("")

  const total = parseBrl(ride.price)
  const fee = Math.round(total * 0.1 * 100) / 100
  const refund = Math.max(total - fee, 0)
  const returnCost = Math.round(total * 0.78 * 100) / 100
  const returnRefund = Math.max(total - returnCost, 0)
  const additionalCharge = Math.max(returnCost - total, 0)
  const requiresReason = ride.status === "waiting_start"
  const reasonValid = reason.trim().length >= 10 && reason.trim().length <= 500
  const canSubmit = !requiresReason || reasonValid

  const closeButton = (
    <button
      onClick={onClose}
      aria-label="Fechar"
      style={{
        width: 34,
        height: 34,
        borderRadius: 12,
        border: `1px solid ${BORDER}`,
        background: CARD,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        cursor: "pointer",
        flexShrink: 0,
      }}
    >
      <IconX size={14} color={DARK} />
    </button>
  )

  const completeSimpleCancellation = () => setStage("success")

  const renderRequest = () => {
    if (ride.status === "on_way_deliver") {
      return (
        <>
          <div style={{ display: "flex", justifyContent: "space-between", gap: 14, marginBottom: 18 }}>
            <div style={{ flex: 1 }}>
              <p style={{ fontSize: 10, fontWeight: 800, color: GOLD, letterSpacing: "0.12em" }}>
                DEVOLUÇÃO DA CARGA
              </p>
              <h2 style={{ fontSize: 22, fontWeight: 850, color: DARK, letterSpacing: -0.5, marginTop: 5 }}>
                Onde devemos devolver?
              </h2>
              <p style={{ fontSize: 12, color: MUTED, lineHeight: "1.55", marginTop: 6 }}>
                Como a mercadoria já foi coletada, precisamos definir um destino de devolução antes de calcular o novo custo.
              </p>
            </div>
            {closeButton}
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 9, marginBottom: 14 }}>
            {([
              {
                id: "origin" as const,
                title: "Devolver ao local de coleta",
                sub: ride.origin,
                icon: <IconUndo size={18} color={GOLD} />,
              },
              {
                id: "other" as const,
                title: "Entregar em outro endereço",
                sub: "Informe um novo destino para a devolução",
                icon: <IconMapPin size={18} color={GOLD} />,
              },
            ]).map((option) => {
              const selected = destination === option.id
              return (
                <button
                  key={option.id}
                  onClick={() => setDestination(option.id)}
                  style={{
                    width: "100%",
                    padding: 14,
                    borderRadius: 15,
                    background: selected ? "rgba(201,162,39,0.07)" : CARD,
                    border: `1.5px solid ${selected ? GOLD : BORDER}`,
                    display: "flex",
                    alignItems: "center",
                    gap: 12,
                    textAlign: "left",
                    cursor: "pointer",
                  }}
                >
                  <div style={{ width: 40, height: 40, borderRadius: 13, background: selected ? DARK : BG, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                    {option.icon}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <p style={{ fontSize: 13, fontWeight: 750, color: DARK }}>{option.title}</p>
                    <p style={{ fontSize: 10.5, color: MUTED, lineHeight: "1.45", marginTop: 3 }}>{option.sub}</p>
                  </div>
                  <div style={{ width: 20, height: 20, borderRadius: 10, border: `1.5px solid ${selected ? GOLD : "#CFCFCB"}`, display: "flex", alignItems: "center", justifyContent: "center" }}>
                    {selected && <div style={{ width: 10, height: 10, borderRadius: 5, background: GOLD }} />}
                  </div>
                </button>
              )
            })}
          </div>

          {destination === "other" && (
            <div style={{ marginBottom: 14 }}>
              <p style={{ fontSize: 10, fontWeight: 700, color: MUTED, letterSpacing: "0.07em", marginBottom: 6 }}>NOVO DESTINO</p>
              <div style={{ display: "flex", alignItems: "center", gap: 9, padding: "12px 13px", borderRadius: 13, background: CARD, border: `1px solid ${BORDER}` }}>
                <IconSearch size={16} color={MUTED} />
                <input
                  value={otherAddress}
                  onChange={(e) => setOtherAddress(e.target.value)}
                  placeholder="Digite um endereço"
                  style={{ flex: 1, border: "none", outline: "none", background: "transparent", fontSize: 12, color: DARK, fontFamily: "inherit" }}
                />
              </div>
              {otherAddress.trim().length > 4 && (
                <button
                  onClick={() => setOtherAddress("Av. Francisco Glicério, 1000 · Campinas")}
                  style={{ width: "100%", marginTop: 7, padding: "10px 12px", borderRadius: 12, border: `1px solid ${BORDER}`, background: BG, textAlign: "left", cursor: "pointer" }}
                >
                  <p style={{ fontSize: 11.5, fontWeight: 650, color: DARK }}>Av. Francisco Glicério, 1000</p>
                  <p style={{ fontSize: 10, color: MUTED, marginTop: 2 }}>Centro · Campinas — SP</p>
                </button>
              )}
            </div>
          )}

          <div style={{ padding: "11px 12px", borderRadius: 13, background: "rgba(201,162,39,0.08)", border: "1px solid rgba(201,162,39,0.20)", marginBottom: 14, display: "flex", gap: 9 }}>
            <IconAlert size={16} color="#8A6A0A" />
            <p style={{ fontSize: 10.5, color: "#735A10", lineHeight: "1.5" }}>
              A corrida ainda não será cancelada. Primeiro o motorista confirmará a posse da carga e o sistema calculará o custo da devolução.
            </p>
          </div>

          <button
            onClick={() => setStage("waiting_driver")}
            disabled={destination === "other" && otherAddress.trim().length < 5}
            style={{ width: "100%", padding: "14px 0", borderRadius: 14, background: destination === "other" && otherAddress.trim().length < 5 ? "#D6D4CF" : DARK, color: CARD, border: "none", cursor: destination === "other" && otherAddress.trim().length < 5 ? "not-allowed" : "pointer", fontSize: 13, fontWeight: 750 }}
          >
            Solicitar cálculo da devolução
          </button>
        </>
      )
    }

    const title = ride.status === "on_way_collect" ? "Cancelar mesmo com o motorista a caminho?" : ride.status === "waiting_start" ? "Deseja cancelar esta corrida?" : "Cancelar esta corrida?"
    const subtitle = ride.status === "on_way_collect"
      ? "O motorista já iniciou o deslocamento até a coleta. Uma taxa de 10% será destinada a ele."
      : ride.status === "waiting_start"
        ? "O motorista já aceitou sua solicitação. Conte rapidamente o motivo do cancelamento."
        : "Ainda não há motorista confirmado. O cancelamento é gratuito e o valor será estornado integralmente."

    return (
      <>
        <div style={{ display: "flex", justifyContent: "space-between", gap: 14, marginBottom: 18 }}>
          <div style={{ flex: 1 }}>
            <p style={{ fontSize: 10, fontWeight: 800, color: "#A62C2C", letterSpacing: "0.12em" }}>CANCELAMENTO</p>
            <h2 style={{ fontSize: 21, fontWeight: 850, color: DARK, letterSpacing: -0.45, marginTop: 5, lineHeight: "1.15" }}>{title}</h2>
            <p style={{ fontSize: 12, color: MUTED, lineHeight: "1.55", marginTop: 7 }}>{subtitle}</p>
          </div>
          {closeButton}
        </div>

        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 10, padding: "12px 13px", background: BG, border: `1px solid ${BORDER}`, borderRadius: 14, marginBottom: 14 }}>
          <div>
            <p style={{ fontSize: 10, color: MUTED }}>Corrida {ride.id}</p>
            <p style={{ fontSize: 12.5, fontWeight: 700, color: DARK, marginTop: 2 }}>{ride.origin.split("—")[0].trim()} → {ride.dest.split("—")[0].trim()}</p>
          </div>
          <StatusBadge status={ride.status} />
        </div>

        {requiresReason && (
          <div style={{ marginBottom: 14 }}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 7 }}>
              <p style={{ fontSize: 11, fontWeight: 700, color: DARK }}>Por que deseja cancelar?</p>
              <span style={{ fontSize: 10, color: reason.length > 500 ? "#A62C2C" : MUTED }}>{reason.length}/500</span>
            </div>
            <textarea
              value={reason}
              maxLength={500}
              onChange={(e) => setReason(e.target.value)}
              placeholder="Ex.: Preciso alterar a data da entrega e não conseguirei receber o motorista agora."
              style={{ width: "100%", minHeight: 105, resize: "none", borderRadius: 14, border: `1.5px solid ${reason.length > 0 && !reasonValid ? "rgba(166,44,44,0.35)" : BORDER}`, background: CARD, padding: "12px 13px", fontFamily: "inherit", fontSize: 12, color: DARK, lineHeight: "1.5", outline: "none", boxSizing: "border-box" }}
            />
            <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 6 }}>
              <div style={{ width: 16, height: 16, borderRadius: 8, background: reasonValid ? "rgba(201,162,39,0.12)" : BG, display: "flex", alignItems: "center", justifyContent: "center" }}>
                {reasonValid ? <IconCheck size={9} color={GOLD} /> : <span style={{ width: 4, height: 4, borderRadius: 3, background: MUTED }} />}
              </div>
              <span style={{ fontSize: 10, color: reasonValid ? "#806515" : MUTED }}>Use entre 10 e 500 caracteres</span>
            </div>
          </div>
        )}

        <div style={{ background: DARK, borderRadius: 16, padding: 14, marginBottom: 14 }}>
          {ride.status === "on_way_collect" ? (
            <>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 9 }}><span style={{ fontSize: 10.5, color: "rgba(255,255,255,0.46)" }}>Valor pago</span><span style={{ fontSize: 11.5, fontWeight: 700, color: CARD }}>{formatBrl(total)}</span></div>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 9 }}><span style={{ fontSize: 10.5, color: "rgba(255,255,255,0.46)" }}>Taxa de cancelamento · 10%</span><span style={{ fontSize: 11.5, fontWeight: 700, color: GOLD }}>− {formatBrl(fee)}</span></div>
              <div style={{ height: 1, background: "rgba(255,255,255,0.08)", margin: "10px 0" }} />
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end" }}><span style={{ fontSize: 11, fontWeight: 650, color: CARD }}>Você receberá de volta</span><span style={{ fontSize: 18, fontWeight: 850, color: CARD }}>{formatBrl(refund)}</span></div>
            </>
          ) : (
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div><p style={{ fontSize: 10, color: "rgba(255,255,255,0.42)" }}>Estorno previsto</p><p style={{ fontSize: 11, color: "rgba(255,255,255,0.62)", marginTop: 3 }}>Sem taxa de cancelamento</p></div>
              <p style={{ fontSize: 20, fontWeight: 850, color: CARD }}>{formatBrl(total)}</p>
            </div>
          )}
        </div>

        <div style={{ display: "flex", gap: 9 }}>
          <button onClick={onClose} style={{ flex: 1, padding: "13px 0", borderRadius: 13, background: CARD, border: `1px solid ${BORDER}`, color: MUTED, cursor: "pointer", fontSize: 12.5, fontWeight: 700 }}>Manter corrida</button>
          <button onClick={completeSimpleCancellation} disabled={!canSubmit} style={{ flex: 1.35, padding: "13px 0", borderRadius: 13, background: canSubmit ? "#A62C2C" : "#D8D6D1", border: "none", color: CARD, cursor: canSubmit ? "pointer" : "not-allowed", fontSize: 12.5, fontWeight: 750 }}>Confirmar cancelamento</button>
        </div>
      </>
    )
  }

  const renderWaitingDriver = () => (
    <>
      <div style={{ display: "flex", justifyContent: "space-between", gap: 14, marginBottom: 18 }}>
        <div style={{ flex: 1 }}>
          <p style={{ fontSize: 10, fontWeight: 800, color: GOLD, letterSpacing: "0.12em" }}>CANCELAMENTO EM ANÁLISE</p>
          <h2 style={{ fontSize: 22, fontWeight: 850, color: DARK, letterSpacing: -0.45, marginTop: 5 }}>Aguardando o motorista</h2>
          <p style={{ fontSize: 12, color: MUTED, lineHeight: "1.55", marginTop: 7 }}>Moreno precisa confirmar que está com a mercadoria e atualizar a localização antes do cálculo.</p>
        </div>
        {closeButton}
      </div>
      <div style={{ background: DARK, borderRadius: 18, padding: 16, marginBottom: 13, position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", right: -32, top: -32, width: 110, height: 110, borderRadius: 60, border: "1px solid rgba(201,162,39,0.17)" }} />
        <div style={{ width: 48, height: 48, borderRadius: 24, background: "rgba(201,162,39,0.12)", display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 13 }}><IconMapPin size={21} color={GOLD} /></div>
        <p style={{ fontSize: 14, fontWeight: 750, color: CARD }}>Sua corrida continua ativa</p>
        <p style={{ fontSize: 11, color: "rgba(255,255,255,0.48)", lineHeight: "1.55", marginTop: 5 }}>A entrega original fica temporariamente bloqueada para finalização enquanto analisamos a devolução.</p>
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 8, marginBottom: 14 }}>
        {["Solicitação enviada ao motorista", "Confirmar posse e localização", "Calcular valor da devolução"].map((item, index) => (
          <div key={item} style={{ display: "flex", alignItems: "center", gap: 10, padding: "10px 11px", borderRadius: 12, background: index === 0 ? "rgba(201,162,39,0.08)" : BG, border: `1px solid ${index === 0 ? "rgba(201,162,39,0.18)" : BORDER}` }}>
            <div style={{ width: 24, height: 24, borderRadius: 12, background: index === 0 ? GOLD : CARD, border: `1px solid ${index === 0 ? GOLD : BORDER}`, display: "flex", alignItems: "center", justifyContent: "center" }}>{index === 0 ? <IconCheck size={10} color={DARK} /> : <span style={{ fontSize: 9, fontWeight: 800, color: MUTED }}>{index + 1}</span>}</div>
            <span style={{ fontSize: 11.5, fontWeight: index === 0 ? 700 : 600, color: index === 0 ? DARK : MUTED }}>{item}</span>
          </div>
        ))}
      </div>
      <button onClick={() => setStage("quote")} style={{ width: "100%", padding: "13px 0", borderRadius: 13, background: GOLD, border: "none", cursor: "pointer", fontSize: 12.5, fontWeight: 750, color: DARK }}>Protótipo · receber confirmação</button>
    </>
  )

  const renderQuote = () => (
    <>
      <div style={{ display: "flex", justifyContent: "space-between", gap: 14, marginBottom: 18 }}>
        <div style={{ flex: 1 }}>
          <p style={{ fontSize: 10, fontWeight: 800, color: GOLD, letterSpacing: "0.12em" }}>ORÇAMENTO PRONTO</p>
          <h2 style={{ fontSize: 22, fontWeight: 850, color: DARK, letterSpacing: -0.45, marginTop: 5 }}>Confira antes de decidir</h2>
          <p style={{ fontSize: 12, color: MUTED, lineHeight: "1.55", marginTop: 7 }}>O valor considera o trecho já realizado e a rota da posição atual do motorista até o destino de devolução.</p>
        </div>
        {closeButton}
      </div>
      <div style={{ background: DARK, borderRadius: 18, padding: 16, marginBottom: 12 }}>
        <p style={{ fontSize: 10, color: "rgba(255,255,255,0.42)" }}>Custo total da devolução</p>
        <p style={{ fontSize: 29, fontWeight: 850, color: CARD, letterSpacing: -0.6, marginTop: 3 }}>{formatBrl(returnCost)}</p>
        <div style={{ height: 1, background: "rgba(255,255,255,0.08)", margin: "14px 0" }} />
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
          <div><p style={{ fontSize: 9.5, color: "rgba(255,255,255,0.38)" }}>JÁ PERCORRIDO</p><p style={{ fontSize: 12, fontWeight: 700, color: CARD, marginTop: 4 }}>18,4 km</p></div>
          <div><p style={{ fontSize: 9.5, color: "rgba(255,255,255,0.38)" }}>ATÉ DEVOLUÇÃO</p><p style={{ fontSize: 12, fontWeight: 700, color: CARD, marginTop: 4 }}>12,7 km</p></div>
        </div>
      </div>
      <div style={{ padding: 14, borderRadius: 15, background: CARD, border: `1px solid ${BORDER}`, marginBottom: 13 }}>
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 9 }}><span style={{ fontSize: 11, color: MUTED }}>Valor já pago</span><span style={{ fontSize: 11.5, fontWeight: 700, color: DARK }}>{formatBrl(total)}</span></div>
        {returnRefund > 0 ? <div style={{ display: "flex", justifyContent: "space-between" }}><span style={{ fontSize: 11, color: MUTED }}>Estorno após confirmação</span><span style={{ fontSize: 13, fontWeight: 800, color: "#4B7B43" }}>{formatBrl(returnRefund)}</span></div> : <div style={{ display: "flex", justifyContent: "space-between" }}><span style={{ fontSize: 11, color: MUTED }}>Cobrança adicional</span><span style={{ fontSize: 13, fontWeight: 800, color: "#A62C2C" }}>{formatBrl(additionalCharge)}</span></div>}
      </div>
      <div style={{ padding: "11px 12px", borderRadius: 13, background: "rgba(201,162,39,0.08)", border: "1px solid rgba(201,162,39,0.18)", marginBottom: 14 }}><p style={{ fontSize: 10.5, color: "#735A10", lineHeight: "1.5" }}>Se você mantiver a entrega, a corrida segue para o destino original e o valor pago permanece o mesmo.</p></div>
      <button onClick={() => setStage("success")} style={{ width: "100%", padding: "14px 0", borderRadius: 14, background: DARK, color: CARD, border: "none", cursor: "pointer", fontSize: 12.5, fontWeight: 750, marginBottom: 8 }}>Confirmar devolução por {formatBrl(returnCost)}</button>
      <button onClick={() => setStage("declined")} style={{ width: "100%", padding: "13px 0", borderRadius: 14, background: CARD, color: DARK, border: `1px solid ${BORDER}`, cursor: "pointer", fontSize: 12.5, fontWeight: 700 }}>Manter entrega original</button>
    </>
  )

  const renderSuccess = () => {
    const isReturn = ride.status === "on_way_deliver"
    const amount = ride.status === "on_way_collect" ? refund : total
    return (
      <div style={{ textAlign: "center", paddingTop: 2 }}>
        <div style={{ width: 70, height: 70, borderRadius: 35, background: DARK, display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 15px", border: "2px solid rgba(201,162,39,0.32)" }}><IconCheck size={29} color={GOLD} /></div>
        <p style={{ fontSize: 10, fontWeight: 800, color: GOLD, letterSpacing: "0.12em" }}>{isReturn ? "DEVOLUÇÃO CONFIRMADA" : "CANCELAMENTO CONCLUÍDO"}</p>
        <h2 style={{ fontSize: 22, fontWeight: 850, color: DARK, letterSpacing: -0.5, marginTop: 6 }}>{isReturn ? "Vamos devolver sua carga" : "Corrida cancelada"}</h2>
        <p style={{ fontSize: 12, color: MUTED, lineHeight: "1.55", margin: "7px auto 16px", maxWidth: 280 }}>{isReturn ? "O motorista foi avisado e seguirá para o destino de devolução selecionado." : ride.status === "waiting_start" ? "O motorista foi avisado e o estorno foi registrado." : "O cancelamento foi registrado e o ajuste financeiro foi concluído no protótipo."}</p>
        <div style={{ padding: 14, borderRadius: 15, background: BG, border: `1px solid ${BORDER}`, textAlign: "left", marginBottom: 14 }}>
          {isReturn ? <><div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}><span style={{ fontSize: 10.5, color: MUTED }}>Novo destino</span><span style={{ maxWidth: 180, textAlign: "right", fontSize: 10.5, fontWeight: 650, color: DARK }}>{destination === "origin" ? "Local de coleta" : otherAddress}</span></div><div style={{ display: "flex", justifyContent: "space-between" }}><span style={{ fontSize: 10.5, color: MUTED }}>Ajuste financeiro</span><span style={{ fontSize: 11.5, fontWeight: 800, color: returnRefund > 0 ? "#4B7B43" : DARK }}>{returnRefund > 0 ? `Estorno de ${formatBrl(returnRefund)}` : additionalCharge > 0 ? `+ ${formatBrl(additionalCharge)}` : "Sem ajuste"}</span></div></> : <><div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}><span style={{ fontSize: 10.5, color: MUTED }}>Status</span><span style={{ fontSize: 10.5, fontWeight: 750, color: "#A62C2C" }}>Cancelada</span></div><div style={{ display: "flex", justifyContent: "space-between" }}><span style={{ fontSize: 10.5, color: MUTED }}>Valor a estornar</span><span style={{ fontSize: 13, fontWeight: 850, color: DARK }}>{formatBrl(amount)}</span></div></>}
        </div>
        <button onClick={onClose} style={{ width: "100%", padding: "14px 0", borderRadius: 14, background: GOLD, border: "none", color: DARK, cursor: "pointer", fontSize: 13, fontWeight: 800 }}>Entendi</button>
      </div>
    )
  }

  const renderDeclined = () => (
    <div style={{ textAlign: "center", paddingTop: 2 }}>
      <div style={{ width: 66, height: 66, borderRadius: 33, background: "rgba(201,162,39,0.10)", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 15px" }}><IconArrow size={25} color={GOLD} /></div>
      <p style={{ fontSize: 10, fontWeight: 800, color: GOLD, letterSpacing: "0.12em" }}>ENTREGA MANTIDA</p>
      <h2 style={{ fontSize: 22, fontWeight: 850, color: DARK, letterSpacing: -0.5, marginTop: 6 }}>Tudo certo, a corrida continua</h2>
      <p style={{ fontSize: 12, color: MUTED, lineHeight: "1.55", margin: "7px auto 17px", maxWidth: 285 }}>A solicitação de cancelamento foi encerrada e Moreno continuará até o destino original.</p>
      <button onClick={onClose} style={{ width: "100%", padding: "14px 0", borderRadius: 14, background: DARK, border: "none", color: CARD, cursor: "pointer", fontSize: 13, fontWeight: 750 }}>Voltar para a corrida</button>
    </div>
  )

  return (
    <div style={{ position: "absolute", inset: 0, zIndex: 50, background: "rgba(12,12,12,0.58)", backdropFilter: "blur(2px)", display: "flex", alignItems: "flex-end", justifyContent: "center", padding: "0 12px 12px" }}>
      <div style={{ width: "100%", maxHeight: "88%", overflowY: "auto", background: "#FBFAF7", borderRadius: "24px 24px 20px 20px", padding: "18px 18px 17px", border: "1px solid rgba(255,255,255,0.58)", boxShadow: "0 -18px 55px rgba(0,0,0,0.24)" }}>
        <div style={{ width: 42, height: 4, borderRadius: 99, background: "#D9D7D2", margin: "0 auto 17px" }} />
        {stage === "request" && renderRequest()}
        {stage === "waiting_driver" && renderWaitingDriver()}
        {stage === "quote" && renderQuote()}
        {stage === "success" && renderSuccess()}
        {stage === "declined" && renderDeclined()}
      </div>
    </div>
  )
}

function RideDetailsModal({
  ride,
  onClose,
  onTrack,
  onCancel,
}: {
  ride: Ride
  onClose: () => void
  onTrack?: () => void
  onCancel?: () => void
}) {
  return (
    <div style={{ position: "absolute", inset: 0, zIndex: 45, background: "rgba(12,12,12,0.55)", backdropFilter: "blur(2px)", display: "flex", alignItems: "flex-end", padding: "0 10px 10px" }}>
      <div className="no-scrollbar" style={{ width: "100%", maxHeight: "90%", overflowY: "auto", background: "#FBFAF7", borderRadius: "25px 25px 20px 20px", padding: "17px 18px 18px", boxShadow: "0 -18px 50px rgba(0,0,0,0.24)" }}>
        <div style={{ width: 42, height: 4, borderRadius: 99, background: "#D8D6D1", margin: "0 auto 16px" }} />
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 12 }}>
          <div><p style={{ fontSize: 10, fontWeight: 750, color: MUTED, letterSpacing: "0.09em" }}>DETALHES DA CORRIDA</p><h2 style={{ fontSize: 22, fontWeight: 850, color: DARK, marginTop: 4 }}>Corrida {ride.id}</h2><p style={{ fontSize: 11, color: MUTED, marginTop: 3 }}>{ride.date}</p></div>
          <StatusBadge status={ride.status} />
        </div>

        <div style={{ marginTop: 17, padding: 15, borderRadius: 17, background: CARD, border: `1px solid ${BORDER}` }}>
          <p style={{ fontSize: 10, fontWeight: 750, color: DARK, marginBottom: 13 }}>ROTA</p>
          {[{ label: "COLETA", address: ride.origin, complement: ride.originComplement, reference: ride.originReference, dot: GOLD }, { label: "ENTREGA", address: ride.dest, complement: ride.destinationComplement, reference: ride.destinationReference, dot: DARK }].map((item, index) => (
            <div key={item.label} style={{ display: "flex", gap: 11, marginBottom: index === 0 ? 15 : 0 }}>
              <div style={{ paddingTop: 4 }}><span style={{ display: "block", width: 9, height: 9, borderRadius: 9, background: item.dot }} /></div>
              <div style={{ flex: 1 }}><p style={{ fontSize: 9.5, color: MUTED }}>{item.label}</p><p style={{ fontSize: 12.2, fontWeight: 650, color: DARK, lineHeight: "1.45", marginTop: 2 }}>{item.address}</p>{item.complement && <p style={{ fontSize: 10.5, color: MUTED, marginTop: 3 }}>{item.complement}</p>}{item.reference && <p style={{ fontSize: 10, color: "#9A7810", marginTop: 3 }}>Referência: {item.reference}</p>}</div>
            </div>
          ))}
        </div>

        {ride.driver && (
          <div style={{ marginTop: 10, padding: 14, borderRadius: 17, background: DARK }}>
            <p style={{ fontSize: 9.5, fontWeight: 750, color: GOLD, letterSpacing: "0.09em", marginBottom: 11 }}>SEU MOTORISTA</p>
            <div style={{ display: "flex", alignItems: "center", gap: 11 }}>
              <UserAvatar size={44} initials="MA" />
              <div style={{ flex: 1 }}><p style={{ fontSize: 13.5, fontWeight: 750, color: CARD }}>{ride.driver.name}</p><p style={{ fontSize: 10.5, color: "rgba(255,255,255,0.46)", marginTop: 3 }}>{ride.driver.vehicle} · {ride.driver.plate}</p></div>
              <div><div style={{ display: "flex", alignItems: "center", gap: 4 }}><IconStar size={12} color={GOLD} /><span style={{ fontSize: 11, fontWeight: 750, color: CARD }}>{ride.driver.rating}</span></div><p style={{ fontSize: 9, color: "rgba(255,255,255,0.35)", marginTop: 2 }}>{ride.driver.rides} corridas</p></div>
            </div>
          </div>
        )}

        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 9, marginTop: 10 }}>
          <div style={{ padding: 13, borderRadius: 15, background: CARD, border: `1px solid ${BORDER}` }}><p style={{ fontSize: 9.5, color: MUTED }}>VALOR</p><p style={{ fontSize: 15, fontWeight: 800, color: DARK, marginTop: 3 }}>{ride.price}</p></div>
          <div style={{ padding: 13, borderRadius: 15, background: CARD, border: `1px solid ${BORDER}` }}><p style={{ fontSize: 9.5, color: MUTED }}>PESO</p><p style={{ fontSize: 15, fontWeight: 800, color: DARK, marginTop: 3 }}>{ride.weight}</p></div>
        </div>
        {(ride.width || ride.height || ride.length) && <div style={{ marginTop: 9, padding: "12px 13px", borderRadius: 14, background: "rgba(201,162,39,0.07)", border: "1px solid rgba(201,162,39,0.17)" }}><p style={{ fontSize: 9.5, color: "#806515", marginBottom: 5 }}>DIMENSÕES DA CARGA</p><p style={{ fontSize: 11.5, fontWeight: 700, color: DARK }}>{ride.width} × {ride.height} × {ride.length}</p></div>}

        {onTrack && ACTIVE_STATUSES.includes(ride.status) && <button onClick={onTrack} style={{ width: "100%", marginTop: 14, padding: "14px 0", borderRadius: 14, background: GOLD, border: "none", color: DARK, cursor: "pointer", fontSize: 13, fontWeight: 800 }}>Acompanhar corrida</button>}
        {onCancel && ACTIVE_STATUSES.includes(ride.status) && <button onClick={onCancel} style={{ width: "100%", marginTop: 8, padding: "12px 0", borderRadius: 13, background: "rgba(166,44,44,0.045)", border: "1px solid rgba(166,44,44,0.18)", color: "#A62C2C", cursor: "pointer", fontSize: 12, fontWeight: 700 }}>Cancelar corrida</button>}
        <button onClick={onClose} style={{ width: "100%", marginTop: 7, padding: "11px 0", border: "none", background: "transparent", color: MUTED, cursor: "pointer", fontSize: 11.5, fontWeight: 650 }}>Fechar</button>
      </div>
    </div>
  )
}

function ClientRideTrackingScreen({ ride = HOME_ACTIVE_RIDE, onBack }: { ride?: Ride; onBack?: () => void }) {
  const [cancellationRide, setCancellationRide] = useState<Ride | null>(null)
  return (
    <>
      <SecondaryHeader title="Acompanhar corrida" onBack={onBack} />
      <div className="flex-1 overflow-y-auto no-scrollbar" style={{ padding: "2px 20px 24px" }}>
        <div style={{ background: DARK, borderRadius: 21, padding: 18, position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", width: 150, height: 150, borderRadius: 999, border: "1px solid rgba(201,162,39,0.18)", right: -48, top: -54 }} />
          <div style={{ position: "relative" }}>
            <StatusBadge status={ride.status} />
            <h2 style={{ fontSize: 21, fontWeight: 850, color: CARD, marginTop: 13 }}>Seu frete está em andamento</h2>
            <p style={{ fontSize: 11.5, lineHeight: "1.55", color: "rgba(255,255,255,0.48)", marginTop: 5 }}>Acompanhe os próximos passos e consulte todas as informações sem precisar voltar ao histórico.</p>
          </div>
        </div>

        <div style={{ marginTop: 11, padding: 15, borderRadius: 17, background: CARD, border: `1px solid ${BORDER}` }}>
          {[{ title: "Motorista encontrado", sub: "Moreno aceitou sua corrida", done: true }, { title: "A caminho da coleta", sub: ride.status === "waiting_start" ? "Aguardando o motorista iniciar" : "Motorista em deslocamento", done: ride.status !== "waiting_start" }, { title: "Entrega", sub: ride.status === "on_way_deliver" ? "Carga a caminho do destino" : "Próxima etapa", done: ride.status === "on_way_deliver" }].map((step, i) => (
            <div key={step.title} style={{ display: "flex", gap: 11, marginBottom: i === 2 ? 0 : 13 }}>
              <div style={{ width: 25, height: 25, borderRadius: 13, background: step.done ? GOLD : BG, border: `1px solid ${step.done ? GOLD : BORDER}`, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>{step.done ? <IconCheck size={11} color={DARK} /> : <span style={{ width: 5, height: 5, borderRadius: 9, background: MUTED }} />}</div>
              <div><p style={{ fontSize: 12.5, fontWeight: 700, color: DARK }}>{step.title}</p><p style={{ fontSize: 10.5, color: MUTED, marginTop: 2 }}>{step.sub}</p></div>
            </div>
          ))}
        </div>

        {ride.driver && <div style={{ marginTop: 11, padding: 15, borderRadius: 17, background: CARD, border: `1px solid ${BORDER}` }}><p style={{ fontSize: 10, fontWeight: 750, color: DARK, marginBottom: 12 }}>MOTORISTA</p><div style={{ display: "flex", alignItems: "center", gap: 11 }}><UserAvatar size={48} initials="MA" /><div style={{ flex: 1 }}><p style={{ fontSize: 14, fontWeight: 750, color: DARK }}>{ride.driver.name}</p><p style={{ fontSize: 10.5, color: MUTED, marginTop: 3 }}>{ride.driver.vehicle} · {ride.driver.plate}</p><div style={{ display: "flex", alignItems: "center", gap: 4, marginTop: 5 }}><IconStar size={11} color={GOLD} /><span style={{ fontSize: 10.5, fontWeight: 700, color: DARK }}>{ride.driver.rating}</span><span style={{ fontSize: 10, color: MUTED }}>· {ride.driver.rides} corridas</span></div></div></div></div>}

        <div style={{ marginTop: 11 }}><RideCard ride={ride} /></div>
        <button onClick={() => setCancellationRide(ride)} style={{ width: "100%", marginTop: 11, padding: "12px 0", borderRadius: 13, background: "rgba(166,44,44,0.045)", border: "1px solid rgba(166,44,44,0.18)", color: "#A62C2C", cursor: "pointer", fontSize: 12, fontWeight: 700 }}>Cancelar corrida</button>
      </div>
      {cancellationRide && <CancellationModal ride={cancellationRide} onClose={() => setCancellationRide(null)} />}
    </>
  )
}

function CancellationShowcaseScreen({
  ride,
  initialStage = "request",
}: {
  ride: Ride
  initialStage?: CancellationStage
}) {
  return (
    <div style={{ flex: 1, position: "relative", overflow: "hidden", background: BG }}>
      <div style={{ padding: "8px 20px" }}>
        <h2 style={{ fontSize: 18, fontWeight: 800, color: DARK }}>Acompanhar corrida</h2>
        <div style={{ marginTop: 14 }}><RideCard ride={ride} /></div>
      </div>
      <CancellationModal ride={ride} initialStage={initialStage} onClose={() => {}} />
    </div>
  )
}

// ─── SCREEN: Corridas ─────────────────────────────────────────────────────────
function CorridasScreen({
  defaultFilter = "all",
  forceEmpty = false,
  nav = "rides",
  setNav,
  onShowAll,
  onTrackRide,
}: {
  defaultFilter?: FilterId
  forceEmpty?: boolean
  nav?: NavId
  setNav?: (n: NavId) => void
  onShowAll?: () => void
  onTrackRide?: (ride: Ride) => void
}) {
  const [activeFilter, setActiveFilter] = useState<FilterId>(defaultFilter)
  const [cancellationRide, setCancellationRide] = useState<Ride | null>(null)
  const [detailsRide, setDetailsRide] = useState<Ride | null>(null)

  const filteredRides = forceEmpty
    ? []
    : activeFilter === "all"
      ? RIDES
      : activeFilter === "active"
        ? RIDES.filter((r) => ACTIVE_STATUSES.includes(r.status))
        : activeFilter === "completed"
          ? RIDES.filter((r) => r.status === "completed")
          : RIDES.filter((r) => r.status === "cancelled")

  return (
    <>
      <div style={{ padding: "4px 20px 0" }}>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            marginBottom: 12,
          }}
        >
          <h1
            style={{
              fontSize: 22,
              fontWeight: 800,
              color: DARK,
              letterSpacing: -0.5,
            }}
          >
            Corridas
          </h1>
          <button
            style={{ background: "none", border: "none", cursor: "pointer" }}
          >
            <IconRefresh size={18} color={GOLD} />
          </button>
        </div>
        <div
          className="no-scrollbar"
          style={{
            display: "flex",
            gap: 8,
            overflowX: "auto",
            paddingBottom: 14,
          }}
        >
          {(Object.keys(FILTER_LABELS) as FilterId[]).map((f) => {
            const isActive = activeFilter === f
            return (
              <button
                key={f}
                onClick={() => setActiveFilter(f)}
                style={{
                  padding: "7px 14px",
                  borderRadius: 99,
                  whiteSpace: "nowrap",
                  fontSize: 12,
                  fontWeight: 600,
                  background: isActive ? GOLD : "transparent",
                  color: isActive ? DARK : MUTED,
                  border: `1px solid ${isActive ? GOLD : BORDER}`,
                  flexShrink: 0,
                  cursor: "pointer",
                }}
              >
                {FILTER_LABELS[f]}
              </button>
            )
          })}
        </div>
      </div>

      <div
        className="flex-1 overflow-y-auto no-scrollbar"
        style={{ padding: "0 20px 8px" }}
      >
        {filteredRides.length === 0 ? (
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              padding: "44px 0",
            }}
          >
            <div
              style={{
                width: 60,
                height: 60,
                borderRadius: 30,
                background: CARD,
                border: `1px solid ${BORDER}`,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                marginBottom: 14,
                boxShadow: "0 1px 6px rgba(0,0,0,0.05)",
              }}
            >
              <IconRouteEmpty size={26} color={GOLD} />
            </div>
            <p
              style={{
                fontSize: 15,
                fontWeight: 600,
                color: DARK,
                marginBottom: 6,
              }}
            >
              Nenhum resultado
            </p>
            <p
              style={{
                fontSize: 13,
                color: MUTED,
                textAlign: "center",
                lineHeight: "1.5",
                marginBottom: 20,
              }}
            >
              Não há corridas com o<br />
              filtro selecionado.
            </p>
            <button
              onClick={() => {
                if (onShowAll) onShowAll()
                else setActiveFilter("all")
              }}
              style={{
                padding: "11px 22px",
                borderRadius: 12,
                background: DARK,
                border: "none",
                cursor: "pointer",
              }}
            >
              <span style={{ fontSize: 13, fontWeight: 600, color: CARD }}>
                Ver todas
              </span>
            </button>
          </div>
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            {filteredRides.map((ride) => (
              <RideCard key={ride.id} ride={ride} onCancel={setCancellationRide} onDetails={setDetailsRide} />
            ))}
          </div>
        )}
      </div>

      <BottomNav active={nav} onSelect={setNav} />
      {detailsRide && (
        <RideDetailsModal
          ride={detailsRide}
          onClose={() => setDetailsRide(null)}
          onTrack={() => {
            setDetailsRide(null)
            onTrackRide?.(detailsRide)
          }}
          onCancel={() => {
            setCancellationRide(detailsRide)
            setDetailsRide(null)
          }}
        />
      )}
      {cancellationRide && (
        <CancellationModal
          ride={cancellationRide}
          onClose={() => setCancellationRide(null)}
        />
      )}
    </>
  )
}

// ─── SCREEN: Pagamentos ───────────────────────────────────────────────────────
function PagamentosScreen({
  hasCards = true,
  nav = "payments",
  setNav,
  onAddCard,
}: {
  hasCards?: boolean
  nav?: NavId
  setNav?: (n: NavId) => void
  onAddCard?: () => void
}) {
  return (
    <>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "4px 20px 14px",
        }}
      >
        <h1
          style={{
            fontSize: 22,
            fontWeight: 800,
            color: DARK,
            letterSpacing: -0.5,
          }}
        >
          Pagamentos
        </h1>
        <button
          style={{
            width: 38,
            height: 38,
            borderRadius: 12,
            background: DARK,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            border: "none",
            cursor: "pointer",
          }}
        >
          <IconPlus size={17} color={CARD} />
        </button>
      </div>

      <div
        className="flex-1 overflow-y-auto no-scrollbar"
        style={{ padding: "0 20px 20px" }}
      >
        {!hasCards ? (
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              paddingTop: 52,
            }}
          >
            <div
              style={{
                width: 72,
                height: 72,
                borderRadius: 36,
                background: CARD,
                border: `1px solid ${BORDER}`,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                marginBottom: 18,
                boxShadow: "0 2px 12px rgba(0,0,0,0.06)",
              }}
            >
              <IconCreditCard size={30} color={GOLD} />
            </div>
            <p
              style={{
                fontSize: 16,
                fontWeight: 700,
                color: DARK,
                marginBottom: 6,
              }}
            >
              Nenhum cartão cadastrado
            </p>
            <p
              style={{
                fontSize: 13,
                color: MUTED,
                textAlign: "center",
                lineHeight: "1.55",
                marginBottom: 28,
              }}
            >
              Adicione um cartão para facilitar
              <br />
              seus pagamentos de frete.
            </p>
            <button
              onClick={onAddCard}
              style={{
                padding: "14px 26px",
                background: GOLD,
                borderRadius: 14,
                border: "none",
                display: "inline-flex",
                alignItems: "center",
                gap: 8,
                cursor: "pointer",
              }}
            >
              <IconPlus size={16} color={DARK} />
              <span style={{ fontSize: 14, fontWeight: 700, color: DARK }}>
                Adicionar cartão
              </span>
            </button>
          </div>
        ) : (
          <>
            <p style={{ fontSize: 12, color: MUTED, marginBottom: 14 }}>
              Gerencie seus métodos de pagamento
            </p>
            <div
              style={{
                display: "flex",
                flexDirection: "column",
                gap: 16,
                marginBottom: 20,
              }}
            >
              {CARDS.map((card) => (
                <div key={card.last4}>
                  <PaymentCardVisual card={card} />
                  <div style={{ display: "flex", gap: 8, marginTop: 10 }}>
                    {!card.isDefault && (
                      <button
                        style={{
                          flex: 1,
                          padding: "9px 0",
                          borderRadius: 10,
                          background: BG,
                          border: `1px solid ${BORDER}`,
                          display: "inline-flex",
                          alignItems: "center",
                          justifyContent: "center",
                          gap: 6,
                          cursor: "pointer",
                        }}
                      >
                        <IconStar size={14} color={DARK} />
                        <span
                          style={{ fontSize: 12, fontWeight: 600, color: DARK }}
                        >
                          Definir padrão
                        </span>
                      </button>
                    )}
                    <button
                      style={{
                        flex: 1,
                        padding: "9px 0",
                        borderRadius: 10,
                        background: BG,
                        border: `1px solid ${BORDER}`,
                        display: "inline-flex",
                        alignItems: "center",
                        justifyContent: "center",
                        gap: 6,
                        cursor: "pointer",
                      }}
                    >
                      <IconTrash size={14} color={MUTED} />
                      <span
                        style={{ fontSize: 12, fontWeight: 500, color: MUTED }}
                      >
                        Remover
                      </span>
                    </button>
                  </div>
                </div>
              ))}
            </div>
            <button
              style={{
                width: "100%",
                padding: "15px 0",
                borderRadius: 16,
                background: "transparent",
                border: `1.5px dashed ${BORDER}`,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                gap: 10,
                cursor: "pointer",
              }}
            >
              <div
                style={{
                  width: 26,
                  height: 26,
                  borderRadius: 8,
                  background: DARK,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                <IconPlus size={14} color={CARD} />
              </div>
              <span style={{ fontSize: 14, fontWeight: 600, color: DARK }}>
                Adicionar novo cartão
              </span>
            </button>
          </>
        )}
      </div>

      <BottomNav active={nav} onSelect={setNav} />
    </>
  )
}

// ─── SCREEN: Perfil (Cliente) ─────────────────────────────────────────────────
function PerfilScreen({
  nav = "profile",
  setNav,
  onDadosPessoais,
  onSeguranca,
  onAjuda,
  onTermos,
  onLogout,
}: {
  nav?: NavId
  setNav?: (n: NavId) => void
  onDadosPessoais?: () => void
  onSeguranca?: () => void
  onAjuda?: () => void
  onTermos?: () => void
  onLogout?: () => void
}) {
  const menu = [
    {
      icon: <IconUser size={20} color={GOLD} />,
      title: "Dados pessoais",
      sub: "Nome, e-mail e telefone",
      onClick: onDadosPessoais,
    },
    {
      icon: <IconShield size={20} color={GOLD} />,
      title: "Segurança e senha",
      sub: "Alterar senha de acesso",
      onClick: onSeguranca,
    },
    {
      icon: <IconHelp size={20} color={GOLD} />,
      title: "Ajuda e suporte",
      sub: "Dúvidas frequentes e contato",
      onClick: onAjuda,
    },
    {
      icon: <IconFileText size={20} color={GOLD} />,
      title: "Termos e privacidade",
      sub: "Termos de uso e seus dados",
      onClick: onTermos,
    },
  ]

  return (
    <>
      <div style={{ padding: "4px 20px 14px" }}>
        <h1
          style={{
            fontSize: 22,
            fontWeight: 800,
            color: DARK,
            letterSpacing: -0.5,
          }}
        >
          Perfil
        </h1>
      </div>

      <div
        className="flex-1 overflow-y-auto no-scrollbar"
        style={{
          padding: "0 20px 20px",
          display: "flex",
          flexDirection: "column",
          gap: 14,
        }}
      >
        <div
          style={{
            background: CARD,
            borderRadius: 20,
            padding: 20,
            border: `1px solid ${BORDER}`,
            boxShadow: "0 1px 8px rgba(0,0,0,0.05)",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
            <UserAvatar size={60} showEdit />
            <div>
              <p style={{ fontSize: 17, fontWeight: 700, color: DARK }}>
                Maria Antonia
              </p>
              <p style={{ fontSize: 12, color: MUTED, marginTop: 2 }}>
                Cliente
              </p>
              <p
                style={{
                  fontSize: 11,
                  color: GOLD,
                  marginTop: 6,
                  fontWeight: 500,
                }}
              >
                cliente@teste.com
              </p>
            </div>
          </div>
          <div
            style={{
              display: "flex",
              gap: 0,
              marginTop: 16,
              paddingTop: 16,
              borderTop: `1px solid ${BORDER}`,
            }}
          >
            {[
              { value: "3", label: "Corridas realizadas" },
              { value: "2026", label: "Membro desde" },
            ].map(({ value, label }, i) => (
              <div
                key={label}
                style={{
                  flex: 1,
                  textAlign: "center",
                  borderLeft: i > 0 ? `1px solid ${BORDER}` : "none",
                }}
              >
                <p style={{ fontSize: 18, fontWeight: 700, color: DARK }}>
                  {value}
                </p>
                <p style={{ fontSize: 11, color: MUTED, marginTop: 2 }}>
                  {label}
                </p>
              </div>
            ))}
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {menu.map(({ icon, title, sub, onClick }) => (
            <QuickCard
              key={title}
              icon={icon}
              title={title}
              sub={sub}
              onClick={onClick}
            />
          ))}
        </div>

        <button
          onClick={onLogout}
          style={{
            width: "100%",
            padding: "15px 0",
            borderRadius: 16,
            background: "transparent",
            border: `1.5px solid rgba(26,26,26,0.12)`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 10,
            cursor: "pointer",
          }}
        >
          <IconLogout size={17} color={MUTED} />
          <span style={{ fontSize: 14, fontWeight: 600, color: MUTED }}>
            Sair da conta
          </span>
        </button>
      </div>

      <BottomNav active={nav} onSelect={setNav} />
    </>
  )
}

// ─── SCREEN: Dados pessoais (Cliente) ─────────────────────────────────────────
function DadosPessoaisScreen({ onBack }: { onBack?: () => void }) {
  return (
    <>
      <SecondaryHeader title="Dados pessoais" onBack={onBack} />

      <div
        className="flex-1 overflow-y-auto no-scrollbar"
        style={{ padding: "4px 20px 0" }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 16,
            marginBottom: 22,
          }}
        >
          <UserAvatar size={68} showEdit />
          <div>
            <p style={{ fontSize: 17, fontWeight: 700, color: DARK }}>
              Maria Antonia
            </p>
            <p style={{ fontSize: 12, color: MUTED, marginTop: 3 }}>
              Cliente · cliente@teste.com
            </p>
          </div>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <div style={{ display: "flex", gap: 10 }}>
            <div style={{ flex: 1 }}>
              <FormField
                label="Nome"
                value="Maria"
                icon={<IconPencil size={14} color={MUTED} />}
              />
            </div>
            <div style={{ flex: 1 }}>
              <FormField
                label="Sobrenome"
                value="Antonia"
                icon={<IconPencil size={14} color={MUTED} />}
              />
            </div>
          </div>
          <FormField
            label="E-mail"
            value="cliente@teste.com"
            icon={<IconPencil size={14} color={MUTED} />}
          />
          <FormField
            label="CPF"
            value="510.109.852-30"
            icon={<IconCheck size={14} color={GOLD} />}
            readOnly
          />
          <FormField
            label="Data de nascimento"
            value="30/11/2003"
            icon={<IconCalendar size={14} color={MUTED} />}
          />
          <FormField
            label="Telefone"
            value="(19) 99999-9999"
            icon={<IconPencil size={14} color={MUTED} />}
          />
          <FormField
            label="Senha"
            value="••••••••••••"
            icon={<IconEye size={14} color={MUTED} />}
          />
        </div>
      </div>

      <div
        style={{
          padding: "14px 20px 20px",
          borderTop: `1px solid ${BORDER}`,
          background: BG,
          flexShrink: 0,
        }}
      >
        <button
          style={{
            width: "100%",
            padding: "15px 0",
            borderRadius: 14,
            background: GOLD,
            border: "none",
            cursor: "pointer",
          }}
        >
          <span
            style={{
              fontSize: 14,
              fontWeight: 700,
              color: DARK,
              letterSpacing: "0.04em",
            }}
          >
            Salvar alterações
          </span>
        </button>
      </div>
    </>
  )
}

// ─── SCREEN: Segurança e senha ────────────────────────────────────────────────
function SegurancaScreen({ onBack }: { onBack?: () => void }) {
  return (
    <>
      <SecondaryHeader title="Segurança e senha" onBack={onBack} />

      <div
        className="flex-1 overflow-y-auto no-scrollbar"
        style={{ padding: "4px 20px 0" }}
      >
        <div
          style={{
            background: CARD,
            borderRadius: 16,
            padding: 16,
            border: `1px solid ${BORDER}`,
            display: "flex",
            alignItems: "center",
            gap: 12,
            marginBottom: 22,
            boxShadow: "0 1px 6px rgba(0,0,0,0.05)",
          }}
        >
          <div
            style={{
              width: 42,
              height: 42,
              borderRadius: 13,
              background: DARK,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              flexShrink: 0,
            }}
          >
            <IconShield size={20} color={GOLD} />
          </div>
          <div>
            <p style={{ fontSize: 13, fontWeight: 600, color: DARK }}>
              Conta protegida
            </p>
            <p style={{ fontSize: 11, color: MUTED, marginTop: 2 }}>
              Última alteração: há 2 meses
            </p>
          </div>
          <div style={{ marginLeft: "auto" }}>
            <div
              style={{
                padding: "4px 10px",
                borderRadius: 99,
                background: "rgba(201,162,39,0.10)",
                border: "1px solid rgba(201,162,39,0.24)",
              }}
            >
              <span style={{ fontSize: 10, fontWeight: 600, color: "#9A7810" }}>
                Ativa
              </span>
            </div>
          </div>
        </div>

        <p
          style={{
            fontSize: 13,
            fontWeight: 700,
            color: DARK,
            marginBottom: 14,
          }}
        >
          Alterar senha
        </p>
        <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <FormField
            label="Senha atual"
            value="••••••••••••"
            icon={<IconEye size={14} color={MUTED} />}
          />
          <FormField
            label="Nova senha"
            value="••••••••••"
            icon={<IconEye size={14} color={MUTED} />}
          />
          <FormField
            label="Confirmar nova senha"
            value="••••••••••"
            icon={<IconEye size={14} color={MUTED} />}
          />
        </div>
        <p
          style={{
            fontSize: 11,
            color: MUTED,
            marginTop: 12,
            lineHeight: "1.6",
          }}
        >
          Use no mínimo 8 caracteres com letras maiúsculas, minúsculas e
          números.
        </p>
      </div>

      <div
        style={{
          padding: "14px 20px 20px",
          borderTop: `1px solid ${BORDER}`,
          background: BG,
          flexShrink: 0,
        }}
      >
        <button
          style={{
            width: "100%",
            padding: "15px 0",
            borderRadius: 14,
            background: GOLD,
            border: "none",
            cursor: "pointer",
          }}
        >
          <span
            style={{
              fontSize: 14,
              fontWeight: 700,
              color: DARK,
              letterSpacing: "0.04em",
            }}
          >
            Atualizar senha
          </span>
        </button>
      </div>
    </>
  )
}

// ─── SCREEN: Login ────────────────────────────────────────────────────────────
function LoginScreen({
  onLogin,
  onForgotPassword,
}: {
  onLogin: (email: string) => void
  onForgotPassword?: () => void
}) {
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [showPass, setShowPass] = useState(false)

  return (
    <div
      style={{
        flex: 1,
        display: "flex",
        flexDirection: "column",
        background: BG,
        padding: "0 24px 28px",
        overflow: "hidden",
      }}
    >
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          paddingTop: 40,
          paddingBottom: 24,
        }}
      >
        <div
          style={{
            width: 70,
            height: 70,
            borderRadius: 22,
            background: DARK,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            marginBottom: 16,
            border: "1px solid rgba(201,162,39,0.22)",
          }}
        >
          <img
            src={logoImg}
            alt="FreteJá"
            style={{ width: 44, height: 44, objectFit: "contain" }}
          />
        </div>
        <h1
          style={{
            fontSize: 26,
            fontWeight: 800,
            color: DARK,
            letterSpacing: -0.6,
            marginBottom: 6,
          }}
        >
          Bem-vindo
        </h1>
        <p
          style={{
            fontSize: 13,
            color: MUTED,
            textAlign: "center",
            lineHeight: "1.5",
          }}
        >
          Acesse ou cadastre-se para continuar.
        </p>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
        <div>
          <p
            style={{
              fontSize: 13,
              fontWeight: 600,
              color: DARK,
              marginBottom: 8,
            }}
          >
            Email
          </p>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 10,
              background: CARD,
              border: `1px solid ${BORDER}`,
              borderRadius: 14,
              padding: "14px 16px",
              boxShadow: "0 1px 4px rgba(0,0,0,0.04)",
            }}
          >
            <IconMail size={17} color={MUTED} />
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="nome@email.com"
              style={{
                flex: 1,
                fontSize: 14,
                color: DARK,
                background: "transparent",
                border: "none",
                outline: "none",
                fontFamily: "inherit",
              }}
            />
          </div>
        </div>
        <div>
          <p
            style={{
              fontSize: 13,
              fontWeight: 600,
              color: DARK,
              marginBottom: 8,
            }}
          >
            Senha
          </p>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 10,
              background: CARD,
              border: `1px solid ${BORDER}`,
              borderRadius: 14,
              padding: "14px 16px",
              boxShadow: "0 1px 4px rgba(0,0,0,0.04)",
            }}
          >
            <IconLock size={17} color={MUTED} />
            <input
              type={showPass ? "text" : "password"}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              style={{
                flex: 1,
                fontSize: 14,
                color: DARK,
                background: "transparent",
                border: "none",
                outline: "none",
                fontFamily: "inherit",
              }}
            />
            <button
              onClick={() => setShowPass(!showPass)}
              style={{
                background: "none",
                border: "none",
                cursor: "pointer",
                padding: 0,
                lineHeight: 0,
              }}
            >
              <IconEye size={16} color={showPass ? GOLD : MUTED} />
            </button>
          </div>
        </div>
        <div
          style={{ display: "flex", justifyContent: "flex-end", marginTop: -4 }}
        >
          <button
            onClick={onForgotPassword}
            style={{
              background: "none",
              border: "none",
              cursor: "pointer",
              padding: 0,
            }}
          >
            <span style={{ fontSize: 13, fontWeight: 600, color: GOLD }}>
              Esqueci minha senha
            </span>
          </button>
        </div>
        <button
          onClick={() => {
            if (email.trim() && password) onLogin(email.trim().toLowerCase())
          }}
          style={{
            width: "100%",
            padding: "16px 0",
            borderRadius: 14,
            background: DARK,
            border: "none",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 8,
            cursor: "pointer",
            marginTop: 2,
          }}
        >
          <span
            style={{
              fontSize: 14,
              fontWeight: 700,
              color: CARD,
              letterSpacing: "0.04em",
            }}
          >
            Entrar
          </span>
          <IconArrow size={14} color={CARD} />
        </button>
      </div>

      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 10,
          margin: "20px 0",
        }}
      >
        <div style={{ flex: 1, height: 1, background: BORDER }} />
        <span style={{ fontSize: 11, color: MUTED }}>ou</span>
        <div style={{ flex: 1, height: 1, background: BORDER }} />
      </div>
      <p style={{ textAlign: "center", fontSize: 13, color: MUTED }}>
        Não possui uma conta?{" "}
        <span style={{ fontWeight: 700, color: DARK }}>Cadastre-se</span>
      </p>
      <div style={{ flex: 1 }} />
      <p
        style={{
          textAlign: "center",
          fontSize: 10,
          color: "rgba(0,0,0,0.2)",
          letterSpacing: "0.06em",
        }}
      >
        V0.0.0
      </p>
    </div>
  )
}

// ─── SCREEN: Recuperar senha ──────────────────────────────────────────────────
function ForgotPasswordScreen({ onBack }: { onBack: () => void }) {
  const [email, setEmail] = useState("")
  return (
    <div
      style={{
        flex: 1,
        display: "flex",
        flexDirection: "column",
        background: BG,
        padding: "0 24px 28px",
        overflow: "hidden",
      }}
    >
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          paddingTop: 40,
          paddingBottom: 24,
        }}
      >
        <div
          style={{
            width: 70,
            height: 70,
            borderRadius: 22,
            background: DARK,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            marginBottom: 16,
            border: "1px solid rgba(201,162,39,0.22)",
          }}
        >
          <img
            src={logoImg}
            alt="FreteJá"
            style={{ width: 44, height: 44, objectFit: "contain" }}
          />
        </div>
        <h1
          style={{
            fontSize: 24,
            fontWeight: 800,
            color: DARK,
            letterSpacing: -0.5,
            marginBottom: 6,
          }}
        >
          Recuperar senha
        </h1>
        <p
          style={{
            fontSize: 13,
            color: MUTED,
            textAlign: "center",
            lineHeight: "1.5",
          }}
        >
          Informe o email cadastrado.
        </p>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
        <div>
          <p
            style={{
              fontSize: 13,
              fontWeight: 600,
              color: DARK,
              marginBottom: 8,
            }}
          >
            Email
          </p>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 10,
              background: CARD,
              border: `1px solid ${BORDER}`,
              borderRadius: 14,
              padding: "14px 16px",
              boxShadow: "0 1px 4px rgba(0,0,0,0.04)",
            }}
          >
            <IconMail size={17} color={MUTED} />
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="nome@email.com"
              style={{
                flex: 1,
                fontSize: 14,
                color: DARK,
                background: "transparent",
                border: "none",
                outline: "none",
                fontFamily: "inherit",
              }}
            />
          </div>
        </div>
        <button
          style={{
            width: "100%",
            padding: "16px 0",
            borderRadius: 14,
            background: DARK,
            border: "none",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 8,
            cursor: "pointer",
            marginTop: 2,
          }}
        >
          <span
            style={{
              fontSize: 14,
              fontWeight: 700,
              color: CARD,
              letterSpacing: "0.04em",
            }}
          >
            Enviar email
          </span>
          <IconArrow size={14} color={CARD} />
        </button>
      </div>

      <div style={{ flex: 1 }} />
      <button
        onClick={onBack}
        style={{
          background: "none",
          border: "none",
          cursor: "pointer",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          gap: 6,
          marginBottom: 10,
        }}
      >
        <IconChevronLeft size={15} color={MUTED} />
        <span style={{ fontSize: 13, fontWeight: 500, color: MUTED }}>
          Voltar para login
        </span>
      </button>
      <p
        style={{
          textAlign: "center",
          fontSize: 10,
          color: "rgba(0,0,0,0.2)",
          letterSpacing: "0.06em",
        }}
      >
        V0.0.0
      </p>
    </div>
  )
}

// ─── SCREEN: Ajuda e suporte (Compartilhada) ──────────────────────────────────
function AjudaSuporteScreen({ onBack }: { onBack?: () => void }) {
  const [search, setSearch] = useState("")
  const [openFaq, setOpenFaq] = useState<number | null>(0)

  const faqs = [
    {
      question: "Como o valor do frete é calculado?",
      answer:
        "O valor é calculado automaticamente considerando distância, características da carga, tipo de veículo necessário, consumo estimado, preço de combustível, custos operacionais, remuneração do motorista e taxa da plataforma. O preço final é sempre exibido antes da confirmação.",
    },
    {
      question: "Posso cancelar uma corrida?",
      answer:
        "O cancelamento depende do estágio da corrida. Antes do início, o processo é mais simples; após o aceite ou início do deslocamento, podem existir regras específicas exibidas no momento da solicitação.",
    },
    {
      question: "Como acompanho uma corrida em andamento?",
      answer:
        "As corridas ativas aparecem na tela inicial e na área de Corridas. Ali você acompanha o status desde o aceite até a finalização da entrega.",
    },
    {
      question: "Sou motorista. Como começo a receber solicitações?",
      answer:
        "Mantenha seu veículo ativo, seus dados atualizados e altere seu status para online. O sistema considera motoristas disponíveis e com localização recente para novas solicitações.",
    },
  ]

  const filteredFaqs = faqs.filter(
    (item) =>
      item.question.toLowerCase().includes(search.trim().toLowerCase()) ||
      item.answer.toLowerCase().includes(search.trim().toLowerCase()),
  )

  return (
    <>
      <SecondaryHeader title="Ajuda e suporte" onBack={onBack} />

      <div
        className="flex-1 overflow-y-auto no-scrollbar"
        style={{ padding: "4px 20px 24px" }}
      >
        <div
          style={{
            background: DARK,
            borderRadius: 20,
            padding: 18,
            marginBottom: 18,
          }}
        >
          <div
            style={{
              width: 42,
              height: 42,
              borderRadius: 13,
              background: "rgba(201,162,39,0.12)",
              border: "1px solid rgba(201,162,39,0.22)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              marginBottom: 12,
            }}
          >
            <IconHelp size={20} color={GOLD} />
          </div>
          <p style={{ fontSize: 17, fontWeight: 700, color: CARD }}>
            Como podemos ajudar?
          </p>
          <p
            style={{
              fontSize: 12,
              color: "rgba(255,255,255,0.48)",
              lineHeight: "1.55",
              marginTop: 5,
            }}
          >
            Encontre respostas rápidas ou fale com nosso suporte.
          </p>
        </div>

        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 10,
            background: CARD,
            border: `1px solid ${BORDER}`,
            borderRadius: 14,
            padding: "12px 14px",
            marginBottom: 20,
            boxShadow: "0 1px 5px rgba(0,0,0,0.04)",
          }}
        >
          <IconSearch size={17} color={MUTED} />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Buscar uma dúvida"
            style={{
              flex: 1,
              border: "none",
              outline: "none",
              background: "transparent",
              fontSize: 13,
              color: DARK,
              fontFamily: "inherit",
            }}
          />
        </div>

        <p
          style={{
            fontSize: 12,
            fontWeight: 700,
            color: DARK,
            marginBottom: 10,
          }}
        >
          Dúvidas frequentes
        </p>

        <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
          {filteredFaqs.map((item, index) => {
            const isOpen = openFaq === index
            return (
              <button
                key={item.question}
                onClick={() => setOpenFaq(isOpen ? null : index)}
                style={{
                  background: CARD,
                  border: `1px solid ${
                    isOpen ? "rgba(201,162,39,0.38)" : BORDER
                  }`,
                  borderRadius: 14,
                  padding: "14px 15px",
                  textAlign: "left",
                  cursor: "pointer",
                  boxShadow: "0 1px 5px rgba(0,0,0,0.04)",
                }}
              >
                <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <span
                    style={{
                      flex: 1,
                      fontSize: 13,
                      fontWeight: 600,
                      color: DARK,
                      lineHeight: "1.4",
                    }}
                  >
                    {item.question}
                  </span>
                  <div
                    style={{
                      transform: isOpen ? "rotate(90deg)" : "none",
                      transition: "transform 120ms ease",
                    }}
                  >
                    <IconChevronRight size={14} color={isOpen ? GOLD : MUTED} />
                  </div>
                </div>
                {isOpen && (
                  <p
                    style={{
                      marginTop: 10,
                      paddingTop: 10,
                      borderTop: `1px solid ${BORDER}`,
                      fontSize: 12,
                      color: MUTED,
                      lineHeight: "1.6",
                    }}
                  >
                    {item.answer}
                  </p>
                )}
              </button>
            )
          })}
        </div>

        {filteredFaqs.length === 0 && (
          <div style={{ padding: "22px 12px", textAlign: "center" }}>
            <p style={{ fontSize: 13, fontWeight: 600, color: DARK }}>
              Nenhuma resposta encontrada
            </p>
            <p style={{ fontSize: 11, color: MUTED, marginTop: 5 }}>
              Tente buscar usando outras palavras.
            </p>
          </div>
        )}

        <div style={{ marginTop: 22 }}>
          <p
            style={{
              fontSize: 12,
              fontWeight: 700,
              color: DARK,
              marginBottom: 10,
            }}
          >
            Ainda precisa de ajuda?
          </p>
          <div
            style={{
              background: CARD,
              borderRadius: 16,
              border: `1px solid ${BORDER}`,
              padding: 15,
              display: "flex",
              alignItems: "center",
              gap: 12,
            }}
          >
            <div
              style={{
                width: 40,
                height: 40,
                borderRadius: 12,
                background: DARK,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                flexShrink: 0,
              }}
            >
              <IconMail size={18} color={GOLD} />
            </div>
            <div style={{ flex: 1 }}>
              <p style={{ fontSize: 13, fontWeight: 600, color: DARK }}>
                Fale com o suporte
              </p>
              <p style={{ fontSize: 11, color: MUTED, marginTop: 2 }}>
                suporte@freteja.com.br
              </p>
            </div>
            <IconChevronRight size={14} color={GOLD} />
          </div>
          <p
            style={{
              fontSize: 10,
              color: MUTED,
              lineHeight: "1.5",
              marginTop: 8,
            }}
          >
            Protótipo: o canal de contato poderá ser integrado ao suporte
            oficial do projeto.
          </p>
        </div>
      </div>
    </>
  )
}

// ─── SCREEN: Termos e privacidade (Compartilhada) ─────────────────────────────
function TermosPrivacidadeScreen({ onBack }: { onBack?: () => void }) {
  const [tab, setTab] = useState<"terms" | "privacy">("terms")

  const sections =
    tab === "terms"
      ? [
          {
            title: "Uso da plataforma",
            text: "O FreteJá conecta clientes que precisam transportar cargas a motoristas disponíveis. Ao utilizar o aplicativo, o usuário se compromete a fornecer informações verdadeiras e utilizar a plataforma de forma responsável.",
          },
          {
            title: "Solicitações e corridas",
            text: "Antes da confirmação, o cliente visualiza as informações disponíveis da solicitação e o valor estimado do frete. O andamento da corrida segue os status apresentados no aplicativo.",
          },
          {
            title: "Valores e pagamentos",
            text: "O preço do frete pode considerar distância, características da carga, veículo necessário, custos operacionais, combustível e regras comerciais vigentes. O valor final é apresentado antes da confirmação.",
          },
          {
            title: "Responsabilidades",
            text: "Clientes e motoristas são responsáveis pela veracidade das informações cadastradas e pelo cumprimento das orientações de segurança aplicáveis ao transporte realizado.",
          },
        ]
      : [
          {
            title: "Dados que utilizamos",
            text: "Podemos tratar dados de cadastro, contato, veículos, documentos, localização e informações relacionadas às corridas para permitir o funcionamento das funcionalidades do aplicativo.",
          },
          {
            title: "Localização",
            text: "Para motoristas, a localização pode ser utilizada enquanto estiverem online para identificar disponibilidade e apoiar o funcionamento das solicitações de frete.",
          },
          {
            title: "Finalidade",
            text: "Os dados são utilizados para autenticação, execução das corridas, cálculo e pagamento de fretes, segurança, suporte e melhoria da experiência no aplicativo.",
          },
          {
            title: "Segurança e controle",
            text: "O projeto busca limitar o acesso aos dados às funcionalidades necessárias. O usuário pode consultar e atualizar dados permitidos pelas opções disponíveis no aplicativo.",
          },
        ]

  return (
    <>
      <SecondaryHeader title="Termos e privacidade" onBack={onBack} />

      <div
        className="flex-1 overflow-y-auto no-scrollbar"
        style={{ padding: "4px 20px 24px" }}
      >
        <div
          style={{
            background: CARD,
            borderRadius: 18,
            padding: 16,
            border: `1px solid ${BORDER}`,
            marginBottom: 16,
            boxShadow: "0 1px 6px rgba(0,0,0,0.04)",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div
              style={{
                width: 42,
                height: 42,
                borderRadius: 13,
                background: DARK,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                flexShrink: 0,
              }}
            >
              <IconShield size={20} color={GOLD} />
            </div>
            <div>
              <p style={{ fontSize: 14, fontWeight: 700, color: DARK }}>
                Transparência e confiança
              </p>
              <p
                style={{
                  fontSize: 11,
                  color: MUTED,
                  marginTop: 3,
                  lineHeight: "1.45",
                }}
              >
                Consulte como a plataforma funciona e como seus dados são
                utilizados.
              </p>
            </div>
          </div>
        </div>

        <div
          style={{
            display: "flex",
            padding: 4,
            background: "#ECEAE5",
            borderRadius: 13,
            marginBottom: 18,
          }}
        >
          <button
            onClick={() => setTab("terms")}
            style={{
              flex: 1,
              padding: "10px 8px",
              borderRadius: 10,
              border: "none",
              background: tab === "terms" ? CARD : "transparent",
              boxShadow:
                tab === "terms" ? "0 1px 4px rgba(0,0,0,0.08)" : "none",
              cursor: "pointer",
            }}
          >
            <span
              style={{
                fontSize: 12,
                fontWeight: 700,
                color: tab === "terms" ? DARK : MUTED,
              }}
            >
              Termos de uso
            </span>
          </button>
          <button
            onClick={() => setTab("privacy")}
            style={{
              flex: 1,
              padding: "10px 8px",
              borderRadius: 10,
              border: "none",
              background: tab === "privacy" ? CARD : "transparent",
              boxShadow:
                tab === "privacy" ? "0 1px 4px rgba(0,0,0,0.08)" : "none",
              cursor: "pointer",
            }}
          >
            <span
              style={{
                fontSize: 12,
                fontWeight: 700,
                color: tab === "privacy" ? DARK : MUTED,
              }}
            >
              Privacidade
            </span>
          </button>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {sections.map((section, index) => (
            <div
              key={section.title}
              style={{
                background: CARD,
                borderRadius: 15,
                border: `1px solid ${BORDER}`,
                padding: 15,
              }}
            >
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 9,
                  marginBottom: 7,
                }}
              >
                <div
                  style={{
                    width: 22,
                    height: 22,
                    borderRadius: 7,
                    background: "rgba(201,162,39,0.12)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    flexShrink: 0,
                  }}
                >
                  <span
                    style={{ fontSize: 10, fontWeight: 800, color: "#9A7810" }}
                  >
                    {index + 1}
                  </span>
                </div>
                <p style={{ fontSize: 13, fontWeight: 700, color: DARK }}>
                  {section.title}
                </p>
              </div>
              <p style={{ fontSize: 11.5, color: MUTED, lineHeight: "1.65" }}>
                {section.text}
              </p>
            </div>
          ))}
        </div>

        <div
          style={{
            marginTop: 16,
            padding: "12px 14px",
            borderRadius: 13,
            background: "rgba(201,162,39,0.08)",
            border: "1px solid rgba(201,162,39,0.20)",
          }}
        >
          <p style={{ fontSize: 10.5, color: "#806515", lineHeight: "1.55" }}>
            Conteúdo demonstrativo do protótipo. A versão final dos termos e da
            política de privacidade deve ser revisada antes da publicação do
            aplicativo.
          </p>
        </div>

        <p
          style={{
            textAlign: "center",
            fontSize: 10,
            color: MUTED,
            marginTop: 14,
          }}
        >
          Última atualização · Setembro de 2026
        </p>
      </div>
    </>
  )
}

// ─── SCREEN: Busca automática de motorista (Cliente) ───────────────────────────
function ClientDispatchSearchScreen({
  extended = false,
  onBack,
  onFound,
  onNoDriver,
}: {
  extended?: boolean
  onBack?: () => void
  onFound?: () => void
  onNoDriver?: () => void
}) {
  const phaseLabel = extended ? "Busca ampliada" : "Busca automática"
  const radiusLabel = extended ? "Região ampliada" : "Motoristas próximos"

  return (
    <>
      <SecondaryHeader title="Buscando motorista" onBack={onBack} />
      <div
        className="flex-1 overflow-y-auto no-scrollbar"
        style={{ padding: "2px 20px 24px" }}
      >
        <div
          style={{
            background: DARK,
            borderRadius: 22,
            padding: 20,
            position: "relative",
            overflow: "hidden",
            marginBottom: 14,
          }}
        >
          <div
            style={{
              position: "absolute",
              width: 180,
              height: 180,
              borderRadius: 999,
              border: "1px solid rgba(201,162,39,0.16)",
              right: -55,
              top: -55,
            }}
          />
          <div
            style={{
              position: "absolute",
              width: 118,
              height: 118,
              borderRadius: 999,
              border: "1px solid rgba(201,162,39,0.24)",
              right: -24,
              top: -24,
            }}
          />
          <div style={{ position: "relative" }}>
            <div
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: 7,
                padding: "5px 10px",
                borderRadius: 99,
                background: "rgba(201,162,39,0.12)",
                border: "1px solid rgba(201,162,39,0.24)",
                marginBottom: 18,
              }}
            >
              <span
                style={{
                  width: 7,
                  height: 7,
                  borderRadius: 99,
                  background: GOLD,
                }}
              />
              <span style={{ fontSize: 10, fontWeight: 700, color: GOLD }}>
                {phaseLabel.toUpperCase()}
              </span>
            </div>
            <div
              style={{
                width: 66,
                height: 66,
                borderRadius: 33,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                background: "rgba(201,162,39,0.11)",
                border: "1px solid rgba(201,162,39,0.26)",
                marginBottom: 16,
              }}
            >
              <IconSearch size={28} color={GOLD} />
            </div>
            <h2
              style={{
                fontSize: 21,
                fontWeight: 800,
                color: CARD,
                letterSpacing: -0.4,
              }}
            >
              Encontrando o melhor motorista
            </h2>
            <p
              style={{
                fontSize: 12.5,
                color: "rgba(255,255,255,0.50)",
                lineHeight: "1.6",
                marginTop: 7,
                maxWidth: 292,
              }}
            >
              Você pode sair desta tela. Continuaremos buscando e avisaremos
              assim que um motorista aceitar sua corrida.
            </p>
          </div>
        </div>

        <div
          style={{
            background: CARD,
            border: `1px solid ${BORDER}`,
            borderRadius: 17,
            padding: 16,
            marginBottom: 12,
          }}
        >
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              gap: 12,
            }}
          >
            <div>
              <p style={{ fontSize: 11, color: MUTED }}>Corrida #34</p>
              <p
                style={{
                  fontSize: 14,
                  fontWeight: 700,
                  color: DARK,
                  marginTop: 3,
                }}
              >
                Campinas → Valinhos
              </p>
            </div>
            <StatusBadge status="waiting_accept" />
          </div>
          <div style={{ display: "flex", gap: 8, marginTop: 14 }}>
            {["R$ 28,40", "12 km", "Hatch"].map((item) => (
              <span
                key={item}
                style={{
                  padding: "5px 8px",
                  borderRadius: 8,
                  background: BG,
                  border: `1px solid ${BORDER}`,
                  fontSize: 11,
                  fontWeight: 600,
                  color: DARK,
                }}
              >
                {item}
              </span>
            ))}
          </div>
        </div>

        <div
          style={{
            background: CARD,
            border: `1px solid ${BORDER}`,
            borderRadius: 17,
            padding: 16,
            marginBottom: 12,
          }}
        >
          <p
            style={{
              fontSize: 12,
              fontWeight: 700,
              color: DARK,
              marginBottom: 14,
            }}
          >
            Como a busca está acontecendo
          </p>
          {[
            {
              title: radiusLabel,
              sub: extended
                ? "Procurando mais longe, mantendo a mesma categoria"
                : "Online, veículo compatível e localização recente",
              active: true,
            },
            {
              title: "Oferta individual",
              sub: extended
                ? "Cada motorista tem alguns minutos para responder"
                : "Enviamos para um motorista por vez",
              active: true,
            },
            {
              title: "Você será notificado",
              sub: "Não precisa manter o aplicativo aberto",
              active: false,
            },
          ].map((step, index) => (
            <div
              key={step.title}
              style={{
                display: "flex",
                gap: 11,
                marginBottom: index === 2 ? 0 : 13,
              }}
            >
              <div
                style={{
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                }}
              >
                <div
                  style={{
                    width: 24,
                    height: 24,
                    borderRadius: 12,
                    background: step.active ? GOLD : BG,
                    border: `1px solid ${step.active ? GOLD : BORDER}`,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                  }}
                >
                  {step.active ? (
                    <IconCheck size={11} color={DARK} />
                  ) : (
                    <span
                      style={{
                        width: 5,
                        height: 5,
                        borderRadius: 9,
                        background: MUTED,
                      }}
                    />
                  )}
                </div>
                {index < 2 && (
                  <div
                    style={{
                      width: 1,
                      height: 24,
                      background: BORDER,
                      marginTop: 4,
                    }}
                  />
                )}
              </div>
              <div style={{ paddingTop: 2 }}>
                <p style={{ fontSize: 12.5, fontWeight: 650, color: DARK }}>
                  {step.title}
                </p>
                <p
                  style={{
                    fontSize: 11,
                    color: MUTED,
                    marginTop: 3,
                    lineHeight: "1.45",
                  }}
                >
                  {step.sub}
                </p>
              </div>
            </div>
          ))}
        </div>

        <div
          style={{
            borderRadius: 14,
            padding: "12px 14px",
            background: "rgba(201,162,39,0.08)",
            border: "1px solid rgba(201,162,39,0.18)",
            marginBottom: 14,
          }}
        >
          <p style={{ fontSize: 11, lineHeight: "1.55", color: "#806515" }}>
            O valor e a categoria da sua corrida não mudam durante a busca.
          </p>
        </div>

        <div style={{ display: "flex", gap: 9 }}>
          <button
            onClick={onNoDriver}
            style={{
              flex: 1,
              padding: "12px 8px",
              borderRadius: 12,
              background: CARD,
              border: `1px solid ${BORDER}`,
              cursor: "pointer",
              fontSize: 11,
              fontWeight: 650,
              color: MUTED,
            }}
          >
            Simular busca sem sucesso
          </button>
          <button
            onClick={onFound}
            style={{
              flex: 1,
              padding: "12px 8px",
              borderRadius: 12,
              background: GOLD,
              border: "none",
              cursor: "pointer",
              fontSize: 11,
              fontWeight: 750,
              color: DARK,
            }}
          >
            Simular aceite
          </button>
        </div>
      </div>
    </>
  )
}

// ─── SCREEN: Busca sem sucesso / decisão do cliente ────────────────────────────
function ClientDispatchRetryScreen({
  onContinue,
  onCancel,
  onBack,
}: {
  onContinue?: () => void
  onCancel?: () => void
  onBack?: () => void
}) {
  return (
    <>
      <SecondaryHeader title="Busca de motorista" onBack={onBack} />
      <div
        className="flex-1 overflow-y-auto no-scrollbar"
        style={{ padding: "8px 20px 24px" }}
      >
        <div style={{ textAlign: "center", padding: "16px 10px 22px" }}>
          <div
            style={{
              width: 72,
              height: 72,
              borderRadius: 36,
              background: CARD,
              border: `1px solid ${BORDER}`,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              margin: "0 auto 16px",
            }}
          >
            <IconRouteEmpty size={31} color={GOLD} />
          </div>
          <h2
            style={{
              fontSize: 20,
              fontWeight: 800,
              color: DARK,
              letterSpacing: -0.4,
            }}
          >
            Ainda não encontramos motorista
          </h2>
          <p
            style={{
              fontSize: 12.5,
              color: MUTED,
              lineHeight: "1.6",
              marginTop: 7,
            }}
          >
            Os motoristas mais próximos não aceitaram ou não responderam à
            solicitação.
          </p>
        </div>

        <div
          style={{
            background: DARK,
            borderRadius: 19,
            padding: 17,
            marginBottom: 12,
          }}
        >
          <p
            style={{
              fontSize: 10,
              fontWeight: 700,
              color: GOLD,
              letterSpacing: "0.08em",
            }}
          >
            SUA CORRIDA CONTINUA PROTEGIDA
          </p>
          <p
            style={{ fontSize: 13, fontWeight: 700, color: CARD, marginTop: 8 }}
          >
            Podemos ampliar a região de busca
          </p>
          <p
            style={{
              fontSize: 11.5,
              color: "rgba(255,255,255,0.48)",
              lineHeight: "1.55",
              marginTop: 5,
            }}
          >
            Procuraremos motoristas mais distantes, mantendo a mesma categoria
            de veículo e o mesmo valor do frete.
          </p>
        </div>

        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 9,
            marginBottom: 18,
          }}
        >
          {[
            "O preço da corrida não aumenta",
            "A categoria do veículo permanece a mesma",
            "Você pode sair do app e será avisado",
          ].map((text) => (
            <div
              key={text}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 10,
                padding: "12px 13px",
                background: CARD,
                border: `1px solid ${BORDER}`,
                borderRadius: 13,
              }}
            >
              <div
                style={{
                  width: 24,
                  height: 24,
                  borderRadius: 12,
                  background: "rgba(201,162,39,0.12)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                <IconCheck size={11} color={GOLD} />
              </div>
              <span style={{ fontSize: 12, color: DARK }}>{text}</span>
            </div>
          ))}
        </div>

        <button
          onClick={onContinue}
          style={{
            width: "100%",
            padding: "15px 0",
            borderRadius: 14,
            background: GOLD,
            border: "none",
            cursor: "pointer",
            fontSize: 13,
            fontWeight: 750,
            color: DARK,
            marginBottom: 9,
          }}
        >
          Continuar procurando
        </button>
        <button
          onClick={onCancel}
          style={{
            width: "100%",
            padding: "14px 0",
            borderRadius: 14,
            background: "transparent",
            border: `1px solid ${BORDER}`,
            cursor: "pointer",
            fontSize: 12.5,
            fontWeight: 650,
            color: MUTED,
          }}
        >
          Cancelar corrida e solicitar estorno
        </button>
        <p
          style={{
            fontSize: 10,
            color: MUTED,
            textAlign: "center",
            lineHeight: "1.5",
            marginTop: 10,
          }}
        >
          No protótipo, o estorno é apenas demonstrativo.
        </p>
      </div>
    </>
  )
}

// ─── SCREEN: Motorista encontrado (Cliente) ───────────────────────────────────
function ClientDriverFoundScreen({ onContinue }: { onContinue?: () => void }) {
  return (
    <div
      className="flex-1 overflow-y-auto no-scrollbar"
      style={{ padding: "24px 20px" }}
    >
      <div style={{ textAlign: "center", paddingTop: 18 }}>
        <div
          style={{
            width: 76,
            height: 76,
            borderRadius: 38,
            background: DARK,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            margin: "0 auto 17px",
            border: "2px solid rgba(201,162,39,0.35)",
          }}
        >
          <IconCheck size={31} color={GOLD} />
        </div>
        <p
          style={{
            fontSize: 10,
            fontWeight: 800,
            letterSpacing: "0.12em",
            color: GOLD,
          }}
        >
          MOTORISTA ENCONTRADO
        </p>
        <h2
          style={{
            fontSize: 23,
            fontWeight: 850,
            color: DARK,
            letterSpacing: -0.5,
            marginTop: 7,
          }}
        >
          Sua corrida foi aceita!
        </h2>
        <p
          style={{
            fontSize: 12.5,
            color: MUTED,
            lineHeight: "1.55",
            marginTop: 7,
          }}
        >
          Moreno está se preparando para iniciar o deslocamento até a coleta.
        </p>
      </div>

      <div
        style={{
          background: CARD,
          border: `1px solid ${BORDER}`,
          borderRadius: 20,
          padding: 17,
          marginTop: 24,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 13 }}>
          <UserAvatar size={54} initials="MA" />
          <div style={{ flex: 1 }}>
            <p style={{ fontSize: 15, fontWeight: 750, color: DARK }}>
              Moreno Antonio
            </p>
            <p style={{ fontSize: 11, color: MUTED, marginTop: 3 }}>
              Toyota Etios · ABC1D23
            </p>
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 5,
                marginTop: 6,
              }}
            >
              <IconStar size={12} color={GOLD} />
              <span style={{ fontSize: 11, fontWeight: 700, color: DARK }}>
                4,9
              </span>
              <span style={{ fontSize: 10.5, color: MUTED }}>
                · 47 corridas
              </span>
            </div>
          </div>
          <div
            style={{
              padding: "5px 9px",
              borderRadius: 99,
              background: "rgba(201,162,39,0.10)",
              border: "1px solid rgba(201,162,39,0.20)",
            }}
          >
            <span style={{ fontSize: 10, fontWeight: 700, color: "#9A7810" }}>
              A caminho
            </span>
          </div>
        </div>
      </div>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "1fr 1fr",
          gap: 10,
          marginTop: 10,
        }}
      >
        <div style={{ background: DARK, borderRadius: 16, padding: 15 }}>
          <p style={{ fontSize: 10, color: "rgba(255,255,255,0.38)" }}>
            Previsão para coleta
          </p>
          <p
            style={{ fontSize: 20, fontWeight: 800, color: CARD, marginTop: 5 }}
          >
            8 min
          </p>
        </div>
        <div
          style={{
            background: CARD,
            borderRadius: 16,
            padding: 15,
            border: `1px solid ${BORDER}`,
          }}
        >
          <p style={{ fontSize: 10, color: MUTED }}>Valor confirmado</p>
          <p
            style={{ fontSize: 20, fontWeight: 800, color: DARK, marginTop: 5 }}
          >
            R$ 28,40
          </p>
        </div>
      </div>

      <button
        onClick={onContinue}
        style={{
          width: "100%",
          padding: "15px 0",
          borderRadius: 14,
          background: GOLD,
          border: "none",
          cursor: "pointer",
          fontSize: 13,
          fontWeight: 750,
          color: DARK,
          marginTop: 20,
        }}
      >
        Acompanhar corrida
      </button>
    </div>
  )
}

// ─── SCREEN: Nova oferta (Motorista) ──────────────────────────────────────────
function DriverOfferScreen({
  onAccept,
  onReject,
}: {
  onAccept?: () => void
  onReject?: () => void
}) {
  const [seconds, setSeconds] = useState(5 * 60)

  useEffect(() => {
    if (seconds <= 0) return
    const timer = window.setTimeout(
      () => setSeconds((value) => Math.max(0, value - 1)),
      1000,
    )
    return () => window.clearTimeout(timer)
  }, [seconds])

  const minutes = Math.floor(seconds / 60)
  const secs = String(seconds % 60).padStart(2, "0")
  const progress = Math.max(0, (seconds / 300) * 100)

  return (
    <>
      <div
        style={{
          padding: "4px 20px 10px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
        }}
      >
        <div>
          <p
            style={{
              fontSize: 10,
              fontWeight: 800,
              color: GOLD,
              letterSpacing: "0.12em",
            }}
          >
            NOVA SOLICITAÇÃO
          </p>
          <h1
            style={{ fontSize: 22, fontWeight: 850, color: DARK, marginTop: 3 }}
          >
            Corrida #34
          </h1>
        </div>
        <div
          style={{ padding: "7px 10px", borderRadius: 11, background: DARK }}
        >
          <span style={{ fontSize: 13, fontWeight: 800, color: CARD }}>
            {minutes}:{secs}
          </span>
        </div>
      </div>

      <div
        className="flex-1 overflow-y-auto no-scrollbar"
        style={{ padding: "4px 20px 16px" }}
      >
        <div
          style={{
            height: 4,
            background: "#E8E6E0",
            borderRadius: 99,
            overflow: "hidden",
            marginBottom: 16,
          }}
        >
          <div
            style={{
              width: `${progress}%`,
              height: "100%",
              background: GOLD,
              borderRadius: 99,
              transition: "width 1s linear",
            }}
          />
        </div>

        <div
          style={{
            background: DARK,
            borderRadius: 21,
            padding: 18,
            marginBottom: 12,
          }}
        >
          <p style={{ fontSize: 11, color: "rgba(255,255,255,0.45)" }}>
            Você receberá
          </p>
          <p
            style={{
              fontSize: 31,
              fontWeight: 850,
              color: CARD,
              letterSpacing: -0.7,
              marginTop: 3,
            }}
          >
            R$ 25,56
          </p>
          <div
            style={{
              height: 1,
              background: "rgba(255,255,255,0.08)",
              margin: "15px 0",
            }}
          />
          <div
            style={{ display: "flex", justifyContent: "space-between", gap: 8 }}
          >
            {[
              { label: "Distância", value: "12 km" },
              { label: "Carga", value: "18 kg" },
              { label: "Veículo", value: "Hatch" },
            ].map((item) => (
              <div key={item.label} style={{ flex: 1 }}>
                <p style={{ fontSize: 9.5, color: "rgba(255,255,255,0.35)" }}>
                  {item.label}
                </p>
                <p
                  style={{
                    fontSize: 12,
                    fontWeight: 700,
                    color: CARD,
                    marginTop: 4,
                  }}
                >
                  {item.value}
                </p>
              </div>
            ))}
          </div>
        </div>

        <div
          style={{
            background: CARD,
            border: `1px solid ${BORDER}`,
            borderRadius: 17,
            padding: 16,
            marginBottom: 12,
          }}
        >
          <p
            style={{
              fontSize: 11,
              fontWeight: 700,
              color: DARK,
              marginBottom: 13,
            }}
          >
            Rota da entrega
          </p>
          <div style={{ display: "flex", gap: 11 }}>
            <div
              style={{
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                paddingTop: 3,
              }}
            >
              <span
                style={{
                  width: 8,
                  height: 8,
                  borderRadius: 9,
                  background: GOLD,
                }}
              />
              <span
                style={{
                  width: 1,
                  height: 34,
                  background: BORDER,
                  margin: "4px 0",
                }}
              />
              <span
                style={{
                  width: 8,
                  height: 8,
                  borderRadius: 9,
                  background: DARK,
                }}
              />
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 17 }}>
              <div>
                <p style={{ fontSize: 9.5, color: MUTED }}>COLETA</p>
                <p
                  style={{
                    fontSize: 12,
                    fontWeight: 650,
                    color: DARK,
                    marginTop: 3,
                  }}
                >
                  Av. Brasil, 500 · Campinas
                </p>
              </div>
              <div>
                <p style={{ fontSize: 9.5, color: MUTED }}>ENTREGA</p>
                <p
                  style={{
                    fontSize: 12,
                    fontWeight: 650,
                    color: DARK,
                    marginTop: 3,
                  }}
                >
                  Rua das Flores, 78 · Valinhos
                </p>
              </div>
            </div>
          </div>
        </div>

        <div
          style={{
            borderRadius: 14,
            padding: "12px 13px",
            background: "rgba(201,162,39,0.08)",
            border: "1px solid rgba(201,162,39,0.18)",
          }}
        >
          <p style={{ fontSize: 11, color: "#806515", lineHeight: "1.5" }}>
            Esta oferta foi selecionada para você com base na sua localização e
            no veículo cadastrado.
          </p>
        </div>
      </div>

      <div
        style={{
          padding: "12px 20px 20px",
          display: "flex",
          gap: 10,
          borderTop: `1px solid ${BORDER}`,
          background: BG,
        }}
      >
        <button
          onClick={onReject}
          disabled={seconds <= 0}
          style={{
            flex: 1,
            padding: "15px 0",
            borderRadius: 14,
            background: CARD,
            border: `1px solid ${BORDER}`,
            cursor: seconds <= 0 ? "not-allowed" : "pointer",
            opacity: seconds <= 0 ? 0.5 : 1,
            fontSize: 13,
            fontWeight: 700,
            color: MUTED,
          }}
        >
          Recusar
        </button>
        <button
          onClick={onAccept}
          disabled={seconds <= 0}
          style={{
            flex: 1.35,
            padding: "15px 0",
            borderRadius: 14,
            background: seconds <= 0 ? "#C8C7C2" : GOLD,
            border: "none",
            cursor: seconds <= 0 ? "not-allowed" : "pointer",
            fontSize: 13,
            fontWeight: 800,
            color: DARK,
          }}
        >
          {seconds <= 0 ? "Oferta expirada" : "Aceitar corrida"}
        </button>
      </div>
    </>
  )
}

// ─── SCREEN: Driver Home ──────────────────────────────────────────────────────
function DriverHomeScreen({
  onNav,
  onLogout,
  onOpenOffer,
}: {
  onNav?: (n: DriverNavId) => void
  onLogout?: () => void
  onOpenOffer?: () => void
}) {
  const [isOnline, setIsOnline] = useState(true)
  const [showBalance, setShowBalance] = useState(false)

  return (
    <>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "4px 20px 10px",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <img
            src={logoImg}
            alt="FreteJá"
            style={{
              width: 36,
              height: 36,
              objectFit: "contain",
              borderRadius: 10,
            }}
          />
          <span style={{ fontSize: 21, fontWeight: 800, letterSpacing: -0.5 }}>
            <span style={{ color: DARK }}>Frete</span>
            <span style={{ color: GOLD }}>Já</span>
          </span>
        </div>
        <button
          onClick={onLogout}
          style={{
            position: "relative",
            width: 40,
            height: 40,
            borderRadius: 14,
            background: DARK,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            border: "none",
            cursor: "pointer",
          }}
        >
          <IconUser size={18} color={CARD} />
          <div
            style={{
              position: "absolute",
              top: 7,
              right: 7,
              width: 9,
              height: 9,
              borderRadius: 5,
              background: isOnline ? "#4CAF50" : "#9E9E9E",
              border: `2px solid ${DARK}`,
            }}
          />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto no-scrollbar">
        <div
          style={{
            padding: "2px 20px 24px",
            display: "flex",
            flexDirection: "column",
            gap: 16,
          }}
        >
          <div>
            <h1
              style={{
                fontSize: 28,
                fontWeight: 800,
                letterSpacing: -0.7,
                color: DARK,
                lineHeight: "1.2",
              }}
            >
              Olá, <span style={{ color: GOLD }}>Moreno!</span>
            </h1>
            <p
              style={{
                fontSize: 13,
                color: MUTED,
                marginTop: 6,
                lineHeight: "1.55",
              }}
            >
              Fique online e deixe o FreteJá encontrar corridas compatíveis para
              você.
            </p>
          </div>

          <div
            style={{
              background: isOnline ? DARK : CARD,
              borderRadius: 18,
              padding: "14px 16px",
              border: isOnline ? "none" : `1px solid ${BORDER}`,
              boxShadow: isOnline ? "none" : "0 1px 6px rgba(0,0,0,0.05)",
            }}
          >
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                gap: 12,
              }}
            >
              <div style={{ flex: 1 }}>
                <p
                  style={{
                    fontSize: 14,
                    fontWeight: 700,
                    color: isOnline ? CARD : DARK,
                  }}
                >
                  {isOnline ? "Você está online" : "Você está offline"}
                </p>
                <p
                  style={{
                    fontSize: 12,
                    color: isOnline ? "rgba(255,255,255,0.46)" : MUTED,
                    marginTop: 4,
                    lineHeight: "1.4",
                  }}
                >
                  {isOnline
                    ? "Disponível para receber novas ofertas"
                    : "Fique online para entrar na busca de motoristas"}
                </p>
              </div>
              <ToggleSwitch value={isOnline} onChange={setIsOnline} />
            </div>
          </div>

          <div
            style={{
              background: CARD,
              borderRadius: 17,
              padding: 16,
              border: `1px solid ${BORDER}`,
              display: "flex",
              alignItems: "center",
              gap: 12,
            }}
          >
            <div
              style={{
                width: 44,
                height: 44,
                borderRadius: 22,
                background: isOnline ? "rgba(201,162,39,0.12)" : BG,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <IconSearch size={20} color={isOnline ? GOLD : MUTED} />
            </div>
            <div style={{ flex: 1 }}>
              <p style={{ fontSize: 13, fontWeight: 700, color: DARK }}>
                {isOnline
                  ? "Procurando oportunidades para você"
                  : "Busca pausada"}
              </p>
              <p
                style={{
                  fontSize: 11,
                  color: MUTED,
                  marginTop: 3,
                  lineHeight: "1.45",
                }}
              >
                {isOnline
                  ? "Quando surgir uma corrida compatível, você receberá uma oferta com tempo para responder."
                  : "Ative seu status para voltar a participar das buscas."}
              </p>
            </div>
          </div>

          {isOnline && (
            <button
              onClick={onOpenOffer}
              style={{
                width: "100%",
                padding: "12px 0",
                borderRadius: 13,
                background: "rgba(201,162,39,0.10)",
                border: "1px dashed rgba(201,162,39,0.38)",
                cursor: "pointer",
                fontSize: 11,
                fontWeight: 700,
                color: "#806515",
              }}
            >
              Protótipo · Simular chegada de uma oferta
            </button>
          )}

          <div
            style={{ background: DARK, borderRadius: 20, padding: "18px 20px" }}
          >
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                marginBottom: 14,
              }}
            >
              <span
                style={{
                  fontSize: 10,
                  fontWeight: 700,
                  color: "rgba(255,255,255,0.38)",
                  letterSpacing: "0.10em",
                  textTransform: "uppercase",
                }}
              >
                Carteira do Motorista
              </span>
              <button
                onClick={() => setShowBalance(!showBalance)}
                style={{
                  background: "none",
                  border: "none",
                  cursor: "pointer",
                  padding: 2,
                  lineHeight: 0,
                }}
              >
                <IconEye size={16} color="rgba(255,255,255,0.46)" />
              </button>
            </div>
            <p
              style={{
                fontSize: 28,
                fontWeight: 800,
                color: CARD,
                letterSpacing: -0.5,
                marginBottom: 16,
              }}
            >
              {showBalance ? "R$ 247,50" : "R$ ••••••"}
            </p>
            <button
              style={{
                width: "100%",
                padding: "11px 0",
                borderRadius: 12,
                background: "rgba(201,162,39,0.13)",
                border: "1px solid rgba(201,162,39,0.24)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                gap: 6,
                cursor: "pointer",
              }}
            >
              <span style={{ fontSize: 13, fontWeight: 600, color: GOLD }}>
                Saldo, histórico e saque
              </span>
              <IconChevronRight size={13} color={GOLD} />
            </button>
          </div>

          <div>
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                marginBottom: 12,
              }}
            >
              <h3 style={{ fontSize: 15, fontWeight: 700, color: DARK }}>
                Corrida em andamento
              </h3>
              <button
                style={{
                  display: "inline-flex",
                  alignItems: "center",
                  gap: 5,
                  background: "none",
                  border: "none",
                  cursor: "pointer",
                  padding: 0,
                }}
              >
                <IconRefresh size={13} color={GOLD} />
                <span style={{ fontSize: 12, fontWeight: 500, color: GOLD }}>
                  Atualizar
                </span>
              </button>
            </div>
            <div
              style={{
                background: CARD,
                borderRadius: 16,
                border: `1px solid ${BORDER}`,
                boxShadow: "0 1px 6px rgba(0,0,0,0.05)",
                overflow: "hidden",
              }}
            >
              <div style={{ padding: 16 }}>
                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "flex-start",
                    marginBottom: 12,
                  }}
                >
                  <div>
                    <p style={{ fontSize: 14, fontWeight: 700, color: DARK }}>
                      Corrida {DRIVER_RIDE.id}
                    </p>
                    <p style={{ fontSize: 11, color: MUTED, marginTop: 2 }}>
                      {DRIVER_RIDE.date}
                    </p>
                  </div>
                  <StatusBadge status={DRIVER_RIDE.status} />
                </div>
                <div
                  style={{ display: "flex", gap: 10, alignItems: "stretch" }}
                >
                  <div
                    style={{
                      display: "flex",
                      flexDirection: "column",
                      alignItems: "center",
                      paddingTop: 2,
                      flexShrink: 0,
                    }}
                  >
                    <div
                      style={{
                        width: 7,
                        height: 7,
                        borderRadius: 99,
                        background: GOLD,
                        flexShrink: 0,
                      }}
                    />
                    <div
                      style={{
                        width: 1,
                        flex: 1,
                        minHeight: 18,
                        background: "rgba(26,26,26,0.12)",
                        margin: "3px 0",
                      }}
                    />
                    <div
                      style={{
                        width: 7,
                        height: 7,
                        borderRadius: 99,
                        background: DARK,
                        flexShrink: 0,
                      }}
                    />
                  </div>
                  <div
                    style={{
                      flex: 1,
                      display: "flex",
                      flexDirection: "column",
                      gap: 10,
                    }}
                  >
                    <p style={{ fontSize: 12, color: DARK, lineHeight: "1.4" }}>
                      {DRIVER_RIDE.origin}
                    </p>
                    <p
                      style={{ fontSize: 12, color: MUTED, lineHeight: "1.4" }}
                    >
                      {DRIVER_RIDE.dest}
                    </p>
                  </div>
                </div>
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 6,
                    marginTop: 12,
                  }}
                >
                  <div
                    style={{
                      padding: "4px 8px",
                      borderRadius: 6,
                      background: BG,
                      border: `1px solid ${BORDER}`,
                    }}
                  >
                    <span
                      style={{ fontSize: 11, fontWeight: 600, color: DARK }}
                    >
                      {DRIVER_RIDE.price}
                    </span>
                  </div>
                  <div
                    style={{
                      padding: "4px 8px",
                      borderRadius: 6,
                      background: BG,
                      border: `1px solid ${BORDER}`,
                    }}
                  >
                    <span style={{ fontSize: 11, color: MUTED }}>
                      {DRIVER_RIDE.weight}
                    </span>
                  </div>
                </div>
              </div>
              <div style={{ padding: "0 12px 12px" }}>
                <button
                  style={{
                    width: "100%",
                    padding: "12px 0",
                    borderRadius: 12,
                    background: DARK,
                    border: "none",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    gap: 8,
                    cursor: "pointer",
                  }}
                >
                  <IconFlag size={14} color={CARD} />
                  <span style={{ fontSize: 13, fontWeight: 700, color: CARD }}>
                    Finalizar entrega
                  </span>
                </button>
              </div>
            </div>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            <QuickCard
              icon={<IconClock size={20} color={GOLD} />}
              title="Histórico de corridas"
              sub="Ver corridas anteriores e finalizadas"
              onClick={() => onNav?.("requests")}
            />
            <QuickCard
              icon={<IconTruck active />}
              title="Meus veículos"
              sub="Gerencie seus veículos cadastrados"
            />
            <QuickCard
              icon={<IconFileText size={20} color={GOLD} />}
              title="Meus documentos"
              sub="CNH, CRLV e habilitações"
            />
          </div>
        </div>
      </div>

      <DriverBottomNav active="home" onSelect={onNav} />
    </>
  )
}

// ─── SCREEN: Driver Corridas (com nav do motorista) ───────────────────────────
function DriverCorridasScreen({ onNav }: { onNav?: (n: DriverNavId) => void }) {
  const [activeFilter, setActiveFilter] = useState<FilterId>("all")
  const filteredRides =
    activeFilter === "all"
      ? RIDES
      : activeFilter === "active"
        ? RIDES.filter((r) => ACTIVE_STATUSES.includes(r.status))
        : activeFilter === "completed"
          ? RIDES.filter((r) => r.status === "completed")
          : RIDES.filter((r) => r.status === "cancelled")

  return (
    <>
      <div style={{ padding: "4px 20px 0" }}>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            marginBottom: 12,
          }}
        >
          <h1
            style={{
              fontSize: 22,
              fontWeight: 800,
              color: DARK,
              letterSpacing: -0.5,
            }}
          >
            Corridas
          </h1>
          <button
            style={{ background: "none", border: "none", cursor: "pointer" }}
          >
            <IconRefresh size={18} color={GOLD} />
          </button>
        </div>
        <div
          className="no-scrollbar"
          style={{
            display: "flex",
            gap: 8,
            overflowX: "auto",
            paddingBottom: 14,
          }}
        >
          {(Object.keys(FILTER_LABELS) as FilterId[]).map((f) => {
            const isActive = activeFilter === f
            return (
              <button
                key={f}
                onClick={() => setActiveFilter(f)}
                style={{
                  padding: "7px 14px",
                  borderRadius: 99,
                  whiteSpace: "nowrap",
                  fontSize: 12,
                  fontWeight: 600,
                  background: isActive ? GOLD : "transparent",
                  color: isActive ? DARK : MUTED,
                  border: `1px solid ${isActive ? GOLD : BORDER}`,
                  flexShrink: 0,
                  cursor: "pointer",
                }}
              >
                {FILTER_LABELS[f]}
              </button>
            )
          })}
        </div>
      </div>

      <div
        className="flex-1 overflow-y-auto no-scrollbar"
        style={{ padding: "0 20px 8px" }}
      >
        {filteredRides.length === 0 ? (
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              padding: "44px 0",
            }}
          >
            <div
              style={{
                width: 60,
                height: 60,
                borderRadius: 30,
                background: CARD,
                border: `1px solid ${BORDER}`,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                marginBottom: 14,
                boxShadow: "0 1px 6px rgba(0,0,0,0.05)",
              }}
            >
              <IconRouteEmpty size={26} color={GOLD} />
            </div>
            <p
              style={{
                fontSize: 15,
                fontWeight: 600,
                color: DARK,
                marginBottom: 6,
              }}
            >
              Nenhum resultado
            </p>
            <p
              style={{
                fontSize: 13,
                color: MUTED,
                textAlign: "center",
                lineHeight: "1.5",
                marginBottom: 20,
              }}
            >
              Não há corridas com o<br />
              filtro selecionado.
            </p>
            <button
              onClick={() => setActiveFilter("all")}
              style={{
                padding: "11px 22px",
                borderRadius: 12,
                background: DARK,
                border: "none",
                cursor: "pointer",
              }}
            >
              <span style={{ fontSize: 13, fontWeight: 600, color: CARD }}>
                Ver todas
              </span>
            </button>
          </div>
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            {filteredRides.map((ride) => (
              <RideCard key={ride.id} ride={ride} />
            ))}
          </div>
        )}
      </div>

      <DriverBottomNav active="requests" onSelect={onNav} />
    </>
  )
}

// ─── SCREEN: Perfil (Motorista) ───────────────────────────────────────────────
function DriverPerfilScreen({
  onNav,
  onDadosPessoais,
  onSeguranca,
  onAjuda,
  onTermos,
  onLogout,
}: {
  onNav?: (n: DriverNavId) => void
  onDadosPessoais?: () => void
  onSeguranca?: () => void
  onAjuda?: () => void
  onTermos?: () => void
  onLogout?: () => void
}) {
  const menu = [
    {
      icon: <IconUser size={20} color={GOLD} />,
      title: "Dados pessoais",
      sub: "Nome, e-mail e telefone",
      onClick: onDadosPessoais,
    },
    {
      icon: <IconShield size={20} color={GOLD} />,
      title: "Segurança e senha",
      sub: "Alterar senha de acesso",
      onClick: onSeguranca,
    },
    {
      icon: <IconHelp size={20} color={GOLD} />,
      title: "Ajuda e suporte",
      sub: "Dúvidas frequentes e contato",
      onClick: onAjuda,
    },
    {
      icon: <IconFileText size={20} color={GOLD} />,
      title: "Termos e privacidade",
      sub: "Termos de uso e seus dados",
      onClick: onTermos,
    },
  ]

  return (
    <>
      <div style={{ padding: "4px 20px 14px" }}>
        <h1
          style={{
            fontSize: 22,
            fontWeight: 800,
            color: DARK,
            letterSpacing: -0.5,
          }}
        >
          Perfil
        </h1>
      </div>

      <div
        className="flex-1 overflow-y-auto no-scrollbar"
        style={{
          padding: "0 20px 20px",
          display: "flex",
          flexDirection: "column",
          gap: 14,
        }}
      >
        <div
          style={{
            background: CARD,
            borderRadius: 20,
            padding: 20,
            border: `1px solid ${BORDER}`,
            boxShadow: "0 1px 8px rgba(0,0,0,0.05)",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
            <UserAvatar size={60} showEdit initials="MA" />
            <div>
              <p style={{ fontSize: 17, fontWeight: 700, color: DARK }}>
                Moreno Antonio
              </p>
              <p style={{ fontSize: 12, color: MUTED, marginTop: 2 }}>
                Motorista
              </p>
              <p
                style={{
                  fontSize: 11,
                  color: GOLD,
                  marginTop: 6,
                  fontWeight: 500,
                }}
              >
                motorista@teste.com
              </p>
            </div>
          </div>
          <div
            style={{
              display: "flex",
              gap: 0,
              marginTop: 16,
              paddingTop: 16,
              borderTop: `1px solid ${BORDER}`,
            }}
          >
            {[
              { value: "47", label: "Corridas realizadas" },
              { value: "2024", label: "Membro desde" },
            ].map(({ value, label }, i) => (
              <div
                key={label}
                style={{
                  flex: 1,
                  textAlign: "center",
                  borderLeft: i > 0 ? `1px solid ${BORDER}` : "none",
                }}
              >
                <p style={{ fontSize: 18, fontWeight: 700, color: DARK }}>
                  {value}
                </p>
                <p style={{ fontSize: 11, color: MUTED, marginTop: 2 }}>
                  {label}
                </p>
              </div>
            ))}
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {menu.map(({ icon, title, sub, onClick }) => (
            <QuickCard
              key={title}
              icon={icon}
              title={title}
              sub={sub}
              onClick={onClick}
            />
          ))}
        </div>

        <button
          onClick={onLogout}
          style={{
            width: "100%",
            padding: "15px 0",
            borderRadius: 16,
            background: "transparent",
            border: `1.5px solid rgba(26,26,26,0.12)`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 10,
            cursor: "pointer",
          }}
        >
          <IconLogout size={17} color={MUTED} />
          <span style={{ fontSize: 14, fontWeight: 600, color: MUTED }}>
            Sair da conta
          </span>
        </button>
      </div>

      <DriverBottomNav active="profile" onSelect={onNav} />
    </>
  )
}

// ─── SCREEN: Dados pessoais (Motorista) ───────────────────────────────────────
function DriverDadosPessoaisScreen({ onBack }: { onBack?: () => void }) {
  return (
    <>
      <SecondaryHeader title="Dados pessoais" onBack={onBack} />

      <div
        className="flex-1 overflow-y-auto no-scrollbar"
        style={{ padding: "4px 20px 0" }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 16,
            marginBottom: 22,
          }}
        >
          <UserAvatar size={68} showEdit initials="MA" />
          <div>
            <p style={{ fontSize: 17, fontWeight: 700, color: DARK }}>
              Moreno Antonio
            </p>
            <p style={{ fontSize: 12, color: MUTED, marginTop: 3 }}>
              Motorista · motorista@teste.com
            </p>
          </div>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <div style={{ display: "flex", gap: 10 }}>
            <div style={{ flex: 1 }}>
              <FormField
                label="Nome"
                value="Moreno"
                icon={<IconPencil size={14} color={MUTED} />}
              />
            </div>
            <div style={{ flex: 1 }}>
              <FormField
                label="Sobrenome"
                value="Antonio"
                icon={<IconPencil size={14} color={MUTED} />}
              />
            </div>
          </div>
          <FormField
            label="E-mail"
            value="motorista@teste.com"
            icon={<IconPencil size={14} color={MUTED} />}
          />
          <FormField
            label="CPF"
            value="321.654.987-00"
            icon={<IconCheck size={14} color={GOLD} />}
            readOnly
          />
          <FormField
            label="Data de nascimento"
            value="15/04/1990"
            icon={<IconCalendar size={14} color={MUTED} />}
          />
          <FormField
            label="Telefone"
            value="(11) 99888-7766"
            icon={<IconPencil size={14} color={MUTED} />}
          />
          <FormField
            label="Senha"
            value="••••••••••••"
            icon={<IconEye size={14} color={MUTED} />}
          />
        </div>
      </div>

      <div
        style={{
          padding: "14px 20px 20px",
          borderTop: `1px solid ${BORDER}`,
          background: BG,
          flexShrink: 0,
        }}
      >
        <button
          style={{
            width: "100%",
            padding: "15px 0",
            borderRadius: 14,
            background: GOLD,
            border: "none",
            cursor: "pointer",
          }}
        >
          <span
            style={{
              fontSize: 14,
              fontWeight: 700,
              color: DARK,
              letterSpacing: "0.04em",
            }}
          >
            Salvar alterações
          </span>
        </button>
      </div>
    </>
  )
}

// ─── SectionBlock ─────────────────────────────────────────────────────────────
function SectionBlock({
  label,
  children,
}: {
  label: string
  children: ReactNode
}) {
  return (
    <div style={{ flexShrink: 0 }}>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 12,
          marginBottom: 18,
        }}
      >
        <div
          style={{ height: 1, width: 24, background: "rgba(255,255,255,0.12)" }}
        />
        <span
          style={{
            fontSize: 10,
            fontWeight: 700,
            color: "rgba(255,255,255,0.32)",
            letterSpacing: "0.14em",
            textTransform: "uppercase",
            whiteSpace: "nowrap",
          }}
        >
          {label}
        </span>
        <div
          style={{ height: 1, flex: 1, background: "rgba(255,255,255,0.07)" }}
        />
      </div>
      <div style={{ display: "flex", gap: 24 }}>{children}</div>
    </div>
  )
}

// ─── App ──────────────────────────────────────────────────────────────────────
export default function App() {
  const [screen, setScreen] = useState<AppScreen>("login")
  const [sharedReturnScreen, setSharedReturnScreen] =
    useState<AppScreen>("client_profile")

  const openSharedScreen = (
    target: "shared_help" | "shared_terms",
    returnTo: AppScreen,
  ) => {
    setSharedReturnScreen(returnTo)
    setScreen(target)
  }

  const clientNav = (n: NavId) => {
    if (n === "home") setScreen("client_home")
    if (n === "rides") setScreen("client_rides_empty")
    if (n === "payments") setScreen("client_payments_empty")
    if (n === "profile") setScreen("client_profile")
  }

  const driverNav = (n: DriverNavId) => {
    if (n === "home") setScreen("driver_home")
    if (n === "requests") setScreen("driver_rides")
    if (n === "profile") setScreen("driver_profile")
  }

  const renderInteractive = (): ReactNode => {
    switch (screen) {
      case "login":
        return (
          <LoginScreen
            onLogin={(email) =>
              setScreen(
                email.includes("motorista") ? "driver_home" : "client_home",
              )
            }
            onForgotPassword={() => setScreen("forgot")}
          />
        )
      case "forgot":
        return <ForgotPasswordScreen onBack={() => setScreen("login")} />

      case "client_home":
        return (
          <HomeScreen
            nav="home"
            setNav={clientNav}
            onSolicitarFrete={() => setScreen("client_dispatch_search")}
            onTrackRide={(ride) => setScreen(ride.status === "waiting_accept" ? "client_dispatch_search" : ride.status === "waiting_start" ? "client_driver_found" : "client_ride_tracking")}
          />
        )
      case "client_dispatch_search":
        return (
          <ClientDispatchSearchScreen
            onBack={() => setScreen("client_home")}
            onFound={() => setScreen("client_driver_found")}
            onNoDriver={() => setScreen("client_dispatch_retry")}
          />
        )
      case "client_dispatch_retry":
        return (
          <ClientDispatchRetryScreen
            onBack={() => setScreen("client_dispatch_search")}
            onContinue={() => setScreen("client_dispatch_search")}
            onCancel={() => setScreen("client_rides_all")}
          />
        )
      case "client_driver_found":
        return (
          <ClientDriverFoundScreen
            onContinue={() => setScreen("client_ride_tracking")}
          />
        )
      case "client_ride_tracking":
        return <ClientRideTrackingScreen ride={HOME_ACTIVE_RIDE} onBack={() => setScreen("client_home")} />
      case "client_rides_empty":
        return (
          <CorridasScreen
            defaultFilter="all"
            forceEmpty
            nav="rides"
            setNav={clientNav}
            onShowAll={() => setScreen("client_rides_all")}
          />
        )
      case "client_rides_all":
        return (
          <CorridasScreen defaultFilter="all" nav="rides" setNav={clientNav} onTrackRide={(ride) => setScreen(ride.status === "waiting_accept" ? "client_dispatch_search" : ride.status === "waiting_start" ? "client_driver_found" : "client_ride_tracking")} />
        )
      case "client_payments_empty":
        return (
          <PagamentosScreen
            hasCards={false}
            nav="payments"
            setNav={clientNav}
            onAddCard={() => setScreen("client_payments_cards")}
          />
        )
      case "client_payments_cards":
        return <PagamentosScreen hasCards nav="payments" setNav={clientNav} />
      case "client_profile":
        return (
          <PerfilScreen
            nav="profile"
            setNav={clientNav}
            onDadosPessoais={() => setScreen("client_personal_data")}
            onSeguranca={() => setScreen("client_security")}
            onAjuda={() => openSharedScreen("shared_help", "client_profile")}
            onTermos={() => openSharedScreen("shared_terms", "client_profile")}
            onLogout={() => setScreen("login")}
          />
        )
      case "client_personal_data":
        return (
          <DadosPessoaisScreen onBack={() => setScreen("client_profile")} />
        )
      case "client_security":
        return <SegurancaScreen onBack={() => setScreen("client_profile")} />

      case "shared_help":
        return (
          <AjudaSuporteScreen onBack={() => setScreen(sharedReturnScreen)} />
        )
      case "shared_terms":
        return (
          <TermosPrivacidadeScreen
            onBack={() => setScreen(sharedReturnScreen)}
          />
        )

      case "driver_home":
        return (
          <DriverHomeScreen
            onNav={driverNav}
            onLogout={() => setScreen("login")}
            onOpenOffer={() => setScreen("driver_offer")}
          />
        )
      case "driver_offer":
        return (
          <DriverOfferScreen
            onAccept={() => setScreen("driver_home")}
            onReject={() => setScreen("driver_home")}
          />
        )
      case "driver_rides":
        return <DriverCorridasScreen onNav={driverNav} />
      case "driver_profile":
        return (
          <DriverPerfilScreen
            onNav={driverNav}
            onDadosPessoais={() => setScreen("driver_personal_data")}
            onSeguranca={() => setScreen("driver_security")}
            onAjuda={() => openSharedScreen("shared_help", "driver_profile")}
            onTermos={() => openSharedScreen("shared_terms", "driver_profile")}
            onLogout={() => setScreen("login")}
          />
        )
      case "driver_personal_data":
        return (
          <DriverDadosPessoaisScreen
            onBack={() => setScreen("driver_profile")}
          />
        )
      case "driver_security":
        return <SegurancaScreen onBack={() => setScreen("driver_profile")} />

      default:
        return (
          <LoginScreen
            onLogin={(email) =>
              setScreen(
                email.includes("motorista") ? "driver_home" : "client_home",
              )
            }
          />
        )
    }
  }

  return (
    <div
      style={{
        minHeight: "100vh",
        background: "#0F0F0F",
        overflowX: "auto",
        overflowY: "auto",
      }}
    >
      <div style={{ padding: "36px 40px 28px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <span
            style={{
              fontSize: 11,
              fontWeight: 700,
              color: GOLD,
              letterSpacing: "0.18em",
              textTransform: "uppercase",
            }}
          >
            FreteJá
          </span>
          <div
            style={{
              width: 3,
              height: 3,
              borderRadius: 99,
              background: "rgba(255,255,255,0.2)",
            }}
          />
          <span
            style={{
              fontSize: 11,
              color: "rgba(255,255,255,0.28)",
              letterSpacing: "0.06em",
            }}
          >
            Redesign · Protótipo Interativo
          </span>
        </div>
      </div>

      <div
        style={{
          display: "flex",
          flexDirection: "column",
          gap: 44,
          padding: "0 40px 64px",
        }}
      >
        <SectionBlock label="Protótipo Interativo — cliente@teste.com · motorista@teste.com">
          <PhoneFrame label="Navegação completa (Login → Cliente ou Motorista)">
            {renderInteractive()}
          </PhoneFrame>
        </SectionBlock>

        <SectionBlock label="Telas — Compartilhadas">
          <PhoneFrame label="Login">
            <LoginScreen onLogin={() => {}} onForgotPassword={() => {}} />
          </PhoneFrame>
          <PhoneFrame label="Recuperar senha">
            <ForgotPasswordScreen onBack={() => {}} />
          </PhoneFrame>
          <PhoneFrame label="Corridas — Vazio">
            <CorridasScreen defaultFilter="all" forceEmpty nav="rides" />
          </PhoneFrame>
          <PhoneFrame label="Corridas — Com registros">
            <CorridasScreen defaultFilter="all" nav="rides" />
          </PhoneFrame>
          <PhoneFrame label="Segurança e senha">
            <SegurancaScreen />
          </PhoneFrame>
          <PhoneFrame label="Ajuda e suporte">
            <AjudaSuporteScreen />
          </PhoneFrame>
          <PhoneFrame label="Termos e privacidade">
            <TermosPrivacidadeScreen />
          </PhoneFrame>
        </SectionBlock>

        <SectionBlock label="Telas — Cliente">
          <PhoneFrame label="Home">
            <HomeScreen nav="home" setNav={() => {}} initialActiveRide />
          </PhoneFrame>
          <PhoneFrame label="Busca automática de motorista">
            <ClientDispatchSearchScreen />
          </PhoneFrame>
          <PhoneFrame label="Busca ampliada / decisão do cliente">
            <ClientDispatchRetryScreen />
          </PhoneFrame>
          <PhoneFrame label="Motorista encontrado">
            <ClientDriverFoundScreen />
          </PhoneFrame>
          <PhoneFrame label="Acompanhar corrida — visão operacional">
            <ClientRideTrackingScreen ride={HOME_ACTIVE_RIDE} />
          </PhoneFrame>
          <PhoneFrame label="Pagamentos — Vazio">
            <PagamentosScreen hasCards={false} nav="payments" />
          </PhoneFrame>
          <PhoneFrame label="Pagamentos — Com cartões">
            <PagamentosScreen hasCards nav="payments" />
          </PhoneFrame>
          <PhoneFrame label="Perfil">
            <PerfilScreen nav="profile" />
          </PhoneFrame>
          <PhoneFrame label="Dados pessoais">
            <DadosPessoaisScreen />
          </PhoneFrame>
        </SectionBlock>

        <SectionBlock label="Fluxos de cancelamento — Cliente">
          <PhoneFrame label="Aguardando aceite · confirmação + estorno integral">
            <CancellationShowcaseScreen ride={RIDES[0]} />
          </PhoneFrame>
          <PhoneFrame label="Aguardando início · justificativa obrigatória">
            <CancellationShowcaseScreen ride={RIDES[1]} />
          </PhoneFrame>
          <PhoneFrame label="A caminho da coleta · taxa de 10%">
            <CancellationShowcaseScreen ride={RIDES[2]} />
          </PhoneFrame>
          <PhoneFrame label="A caminho da entrega · escolher devolução">
            <CancellationShowcaseScreen ride={RIDES[3]} />
          </PhoneFrame>
          <PhoneFrame label="Em entrega · aguardando motorista">
            <CancellationShowcaseScreen ride={RIDES[3]} initialStage="waiting_driver" />
          </PhoneFrame>
          <PhoneFrame label="Em entrega · orçamento da devolução">
            <CancellationShowcaseScreen ride={RIDES[3]} initialStage="quote" />
          </PhoneFrame>
        </SectionBlock>

        <SectionBlock label="Telas — Motorista">
          <PhoneFrame label="Home — aguardando ofertas">
            <DriverHomeScreen />
          </PhoneFrame>
          <PhoneFrame label="Nova oferta — aceite em até 5 min">
            <DriverOfferScreen />
          </PhoneFrame>
          <PhoneFrame label="Perfil">
            <DriverPerfilScreen />
          </PhoneFrame>
          <PhoneFrame label="Dados pessoais">
            <DriverDadosPessoaisScreen />
          </PhoneFrame>
        </SectionBlock>
      </div>
    </div>
  )
}
